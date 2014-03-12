require 'socket'
require 'timeout'
require 'yell'

require 'lifx/network_context'
require 'lifx/light_collection'

module LIFX
  class Client
    class << self
      # Returns a LIFX::Client set up for accessing devices on the LAN
      #
      # @return [Client] A LAN LIFX::Client
      def lan
        @lan ||= new
      end

      # Returns a LIFX::Light that's set up to talk to the virtual bulb
      # located at http://virtualbulb.lifx.co.
      # 
      # For this to work, you must have the page loaded and be accessing it
      # from the same public IP.
      # @return [Light] A Light that represents your virtual bulb instance
      def virtual_bulb
        @virtual_bulb ||= begin
          @virtual_bulb_client = new(transport: :virtual_bulb)
          @virtual_bulb_client.discover
          @virtual_bulb_client.lights.first
        end
      end
    end

    extend Forwardable

    # @return [NetworkContext] Refers to the client's network context
    attr_reader :context

    # @param transport: [:lan, :virtual_bulb] Specify which transport to use
    def initialize(transport: :lan)
      @context = NetworkContext.new(transport: transport)
    end

    # Default timeout in seconds for discovery
    DISCOVERY_DEFAULT_TIMEOUT = 10

    # This method tells the [NetworkContext] to look for devices, and will block
    # until there's at least one device.
    # 
    # @param timeout: [Numeric] How long to try to wait for before returning
    # @return [LightCollection] A collection of the lights that have been discovered.
    def discover(timeout: DISCOVERY_DEFAULT_TIMEOUT)
      Timeout.timeout(timeout) do
        @context.discover
        while lights.empty?
          sleep 0.1
        end
        lights
      end
    rescue Timeout::Error
      lights
    end

    # @return [LightCollection] Lights available to the client
    # @see [NetworkContext#lights]
    def lights
      context.lights
    end

    # @return [Array<String>] All tags visible to the client
    # @see [NetworkContext#tags]
    def tags
      context.tags
    end

    # @return [Array<String>] Tags that are currently unused by known devices
    # @see [NetworkContext#unused_tags]
    def unused_tags
      context.unused_tags
    end

    # Purges unused tags from the system.
    # Should only use when all devices are on the network, otherwise
    # offline devices using their tags will not be tagged correctly.
    # @see [NetworkContext#purge_unused_tags!]
    def purge_unused_tags!
      context.purge_unused_tags!
    end

    # Asks all devices on the network to send their state. Asynchronous, so the
    # lights returned may not have updated yet.
    # @return [LightCollection] (see #lights)
    def refresh
      context.refresh
    end

    # Blocks until all messages have been sent to the gateways
    # @see [NetworkContext#flush]
    def flush(**args)
      context.flush(**args)
    end
  end
end
