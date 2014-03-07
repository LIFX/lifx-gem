require 'lifx/gateway_connection'

module LIFX
  module TransportManager
    class VirtualBulb < Base
      attr_reader :host, :port

      def initialize(host: 'virtualbulb.lifx.co', port: 56750)
        @host = host
        @port = port
      end

      def discover
        @gateway = GatewayConnection.new
        @gateway.add_observer(self) do |**args|
          notify_observers(**args)
        end
        @gateway.connect(host, port)
        write(Message.new(path: ProtocolPath.new(tagged: true), payload: Protocol::Light::Get.new))
      end

      def write(message)
        @gateway.write(message)
      end

      def stop
        @gateway.close
      end

      def flush(**options)
        @gateway.flush(**options)
      end
    end
  end
end
