require 'lifx/gateway_connection'
require 'lifx/site'

module LIFX
  module TransportManager
    class Base
      include Logging

      # TransportManager handles sending and receiving messages
      # The LAN TM will handle discovery and connection management
      # The Virtual Bulb will simply connect to the virtual bulb service
      def initialize

      end

      def connect
        raise NotImplementedError
      end

      def write(message)
        raise NotImplementedError
      end

      def add_observer(obj, &callback)
        raise NotImplementedError
      end
    end

    class VirtualBulb < Base
      def initialize

      end

      def connect

      end
    end

    class LAN < Base
      def initialize(bind_ip: '0.0.0.0', send_ip: '255.255.255.255', port: 56700)
        @bind_ip = bind_ip
        @send_ip = send_ip
        @port    = port

        @sites = {}
        initialize_transport
      end

      def on_message(&block)
        @message_handler = block
      end

      def connect
        discover
      end

      DISCOVERY_INTERVAL_WHEN_NO_SITES_FOUND = 1    # seconds
      DISCOVERY_INTERVAL                     = 20   # seconds
      def discover
        stop_discovery
        Thread.abort_on_exception = true
        @discovery_thread = Thread.new do
          message = Message.new(path: ProtocolPath.new(tagged: true), payload: Protocol::Device::GetPanGateway.new)
          logger.info("Discovering gateways on #{@bind_ip}:#{@port}")
          loop do
            write(message)
            if @sites.empty?
              sleep(DISCOVERY_INTERVAL_WHEN_NO_SITES_FOUND)
            else
              sleep(DISCOVERY_INTERVAL)
            end
          end
        end
      end

      def stop_discovery
        Thread.kill(@discovery_thread) if @discovery_thread
      end

      def close

      end

      def write(message)
        if message.path.all_sites?
          @transport.write(message)
        else
          @sites[message.path.site_id].write(message)
        end
      end

      protected

      def initialize_transport
        @transport = Transport::UDP.new(@send_ip, @port)
        @transport.listen(ip: @bind_ip) do |message, ip|
          handle_broadcast_message(message, ip, @transport)
        end
      end

      def handle_broadcast_message(message, ip, transport)
        payload = message.payload
        case payload
        when Protocol::Device::StatePanGateway
          if !@sites.has_key?(message.path.site_id)
            @sites[message.path.site_id] = Site.new(message.path.site_id)
            @sites[message.path.site_id].on_message do |*args|
              @message_handler.call(*args)
            end
          end
          @sites[message.path.site_id].handle_message(message, ip, transport)
        end
      end
    end
  end
end
