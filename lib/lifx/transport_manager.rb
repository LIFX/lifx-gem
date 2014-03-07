require 'lifx/observable'

module LIFX
  module TransportManager
    class Base
      include Logging
      include Observable
      # TransportManager handles sending and receiving messages
      # The LAN TM will handle discovery and connection management
      # The Virtual Bulb will simply connect to the virtual bulb service
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
require 'lifx/transport_manager/virtual_bulb'
