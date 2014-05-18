require 'lifx/site'

module LIFX
  module TransportManager
    class LAN < Base
      include Timers
      def initialize(bind_ip: '0.0.0.0', send_ip: Config.broadcast_ip, port: 56700, peer_port: 56750)
        super
        @bind_ip   = bind_ip
        @send_ip   = send_ip
        @port      = port
        @peer_port = peer_port

        @sites = {}
        @threads = []
        @threads << initialize_timer_thread
        initialize_transports
        initialize_periodic_refresh
        initialize_message_rate_updater
      end

      def flush(**options)
        @sites.values.map do |site|
          Thread.start do
            site.flush(**options)
          end
        end.each(&:join)
      end

      DISCOVERY_INTERVAL_WHEN_NO_SITES_FOUND = 1    # seconds
      DISCOVERY_INTERVAL                     = 15   # seconds
      def discover
        stop_discovery
        @discovery_thread = Thread.start do
          @last_request_seen = Time.at(0)
          message = Message.new(path: ProtocolPath.new(tagged: true), payload: Protocol::Device::GetPanGateway.new)
          logger.info("Discovering gateways on #{@bind_ip}:#{@port}")
          loop do
            interval = @sites.empty? ?
              DISCOVERY_INTERVAL_WHEN_NO_SITES_FOUND :
              DISCOVERY_INTERVAL
            if Time.now - @last_request_seen > interval
              write(message)
            end
            sleep(interval / 2.0)
          end
        end
      end

      def stop_discovery
        if @discovery_thread
          @discovery_thread.abort
        end
      end

      def stop
        super
        stop_discovery
        stop_timers
        @threads.each do |thr|
          thr.abort
        end
        @peer_transport.close
        @transport.close
        @sites.values.each do |site|
          site.stop
        end
      end

      def write(message)
        return unless on_network?
        if message.path.all_sites?
          broadcast(message)
        else
          site = @sites[message.path.site_id]
          if site
            site.write(message)
          else
            broadcast(message)
          end
        end
        broadcast_to_peers(message)
      end

      def on_network?
        if Socket.respond_to?(:getifaddrs) # Ruby 2.1+
          Socket.getifaddrs.any? { |ifaddr| ifaddr.broadaddr }
        else # Ruby 2.0
          Socket.ip_address_list.any? do |addrinfo|
            # Not entirely sure how to check if on a LAN with IPv6
            addrinfo.ipv4_private? || (addrinfo.respond_to?(:ipv6_unique_local?) && addrinfo.ipv6_unique_local?)
          end
        end
      end

      def broadcast(message)
        if !@transport.connected?
          create_broadcast_transport
        end
        @transport.write(message)
      end

      def broadcast_to_peers(message)
        if !@peer_transport.connected?
          create_peer_transport
        end
        @peer_transport.write(message)
      end

      def sites
        @sites.dup
      end

      def gateways
        @sites.values.map(&:gateways).map(&:keys).flatten.uniq.map { |id| context.lights.with_id(id) }
      end

      def gateway_connections
        @sites.values.map(&:gateways).map(&:values).flatten
      end

      protected

      def initialize_periodic_refresh
        timers.every(10) do
          context.refresh(force: false)
        end
      end

      def initialize_message_rate_updater
        timers.every(5) do
          missing_mesh_firmware = context.lights.alive.select { |l| l.mesh_firmware(fetch: false).nil? }
          if missing_mesh_firmware.count > 10
            context.send_message(target: Target.new(broadcast: true), payload: Protocol::Device::GetMeshFirmware.new)
          elsif missing_mesh_firmware.count > 0
            missing_mesh_firmware.each { |l| l.send_message(Protocol::Device::GetMeshFirmware.new) }
          else
            @message_rate = context.lights.alive.all? do |light|
              m = light.mesh_firmware(fetch: false)
              m && m >= '1.2'
            end ? 20 : 5
            gateway_connections.each do |connection|
              connection.set_message_rate(@message_rate)
            end
          end
        end
      end

      DEFAULT_MESSAGING_RATE = 5 # per second
      def message_rate
        @message_rate || 5
      end

      def initialize_transports
        create_broadcast_transport
        create_peer_transport
      end

      def create_broadcast_transport
        @transport = Transport::UDP.new(@send_ip, @port)
        @transport.add_observer(self, :message_received) do |message: nil, ip: nil, transport: nil|
          handle_broadcast_message(message, ip, @transport)
          notify_observers(:message_received, message: message, ip: ip, transport: transport)
        end
        @transport.listen(ip: @bind_ip)
      end

      def create_peer_transport
        @peer_transport = Transport::UDP.new('255.255.255.255', @peer_port)
        @peer_transport.add_observer(self, :message_received) do |message: nil, ip: nil, transport: nil|
          notify_observers(:message_received, message: message, ip: ip, transport: transport)
        end
        @peer_transport.listen(ip: @bind_ip)
      end

      def handle_broadcast_message(message, ip, transport)
        return if message.nil?
        payload = message.payload
        case payload
        when Protocol::Device::StatePanGateway
          if !@sites.has_key?(message.path.site_id)
            @sites[message.path.site_id] = Site.new(id: message.path.site_id)
            @sites[message.path.site_id].add_observer(self, :message_received) do |**args|
              notify_observers(:message_received, **args)
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
