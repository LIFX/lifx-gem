require 'lifx/site'

module LIFX
  module TransportManager
    class LAN < Base
      def initialize(bind_ip: '0.0.0.0', send_ip: '255.255.255.255', port: 56700, peer_port: 56750)
        super
        @bind_ip   = bind_ip
        @send_ip   = send_ip
        @port      = port
        @peer_port = peer_port
        
        @sites = {}
        initialize_transports
      end

      def flush(**options)
        @sites.values.map do |site|
          Thread.new do
            site.flush(**options)
          end
        end.each(&:join)
      end

      DISCOVERY_INTERVAL_WHEN_NO_SITES_FOUND = 1    # seconds
      DISCOVERY_INTERVAL                     = 15   # seconds
      def discover
        stop_discovery
        Thread.abort_on_exception = true
        @discovery_thread = Thread.new do
          @last_request_seen = Time.at(0)
          message = Message.new(path: ProtocolPath.new(tagged: true), payload: Protocol::Device::GetPanGateway.new)
          logger.info("Discovering gateways on #{@bind_ip}:#{@port}")
          loop do
            interval = @sites.empty? ?
              DISCOVERY_INTERVAL_WHEN_NO_SITES_FOUND :
              DISCOVERY_INTERVAL
            if Time.now - @last_request_seen > interval
              write(message)
              @sites.values.each(&:scan_lights)
            end
            sleep(interval / 2.0)
          end
        end
      end

      def stop_discovery
        Thread.kill(@discovery_thread) if @discovery_thread
      end

      def stop
        stop_discovery
        @transport.close
        @sites.values.each do |site|
          site.stop
        end
      end

      def write(message)
        check_transports
        if message.path.all_sites?
          @transport.write(message)
        else
          site = @sites[message.path.site_id]
          if site
            site.write(message)
          else
            @transport.write(message)
          end
        end
        @peer_transport.write(message)
      end

      def sites
        @sites.dup
      end

      def gateways
        @sites.values.map(&:gateways)
      end

      protected

      def initialize_transports
        @transport = Transport::UDP.new(@send_ip, @port)
        @transport.add_observer(self) do |message:, ip:, transport:|
          handle_broadcast_message(message, ip, @transport)
          notify_observers(message: message, ip: ip, transport: transport)
        end
        @transport.listen(ip: @bind_ip)

        create_peer_transport
      end

      def create_peer_transport
        @peer_transport = Transport::UDP.new('255.255.255.255', @peer_port)
      end

      def check_transports
        if !@peer_transport.connected?
          create_peer_transport
        end
      end


      def handle_broadcast_message(message, ip, transport)
        payload = message.payload
        case payload
        when Protocol::Device::StatePanGateway
          if !@sites.has_key?(message.path.site_id)
            @sites[message.path.site_id] = Site.new(id: message.path.site_id)
            @sites[message.path.site_id].add_observer(self) do |**args|
              notify_observers(**args)
            end
          end
          @sites[message.path.site_id].handle_message(message, ip, transport)
        when Protocol::Device::GetPanGateway
          @last_request_seen = Time.now
        end
      end
    end
  end
end
