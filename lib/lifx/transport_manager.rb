require 'lifx/observable'

module LIFX
  # @api private
  module TransportManager
    class Base
      include Logging
      include Observable

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
        raise NotImplementedError
      end


    end
  end
end

require 'lifx/transport_manager/lan'
