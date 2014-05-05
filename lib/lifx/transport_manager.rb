require 'lifx/observable'

module LIFX
  # @api private
  module TransportManager
    class Base
      include Logging
      include Observable
      attr_accessor :context

      def initialize(**args)
      end

      def discover
        raise NotImplementedError
      end

      def write(message)
        raise NotImplementedError
      end

      def flush(**options)
        raise NotImplementedError
      end

      def stop
        @context = nil
        remove_observers
      end

      def observer_callback_definition
        {
          message_received: -> (message: nil, ip: nil, transport: nil) {},
          disconnected: -> {}
        }
      end
    end
  end
end

require 'lifx/transport_manager/lan'
