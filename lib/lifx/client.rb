require 'socket'
require 'timeout'
require 'yell'

require 'lifx/network_context'
require 'lifx/light_collection'

module LIFX
  # {LIFX::Client} is the top level interface to the library. It mainly maps
  # methods to the backing {NetworkContext} instance.
  class Client

    class << self
      # Returns a {Client} set up for accessing devices on the LAN
      #
      # @return [Client] A LAN LIFX::Client
      def lan
        @lan ||= new
      end
    end

    extend Forwardable
    include Utilities

    # Refers to the client's network context.
    # @return [NetworkContext] Enclosed network context
    attr_reader :context

    # @param transport: [:lan] Specify which transport to use
    def initialize(transport: :lan)
      @context = NetworkContext.new(transport: transport)
    end

    # Default timeout in seconds for discovery
    DISCOVERY_DEFAULT_TIMEOUT = 10

    # This method tells the {NetworkContext} to look for devices asynchronously.
    # @return [Client] self
    def discover
      @context.discover
    end

    # This method tells the {NetworkContext} to look for devices, and will block
    # until there's at least one device.
    # 
    # @param timeout: [Numeric] How long to try to wait for before returning
    # @param condition_interval: [Numeric] Seconds between evaluating the block
    # @yield [Client] This block is evaluated every `condition_interval` seconds. If true, method returns. If no block is supplied, it will block until it finds at least one light.
    # @return [Client] self
    def discover!(timeout: DISCOVERY_DEFAULT_TIMEOUT, condition_interval: 0.1, &block)
      block ||= -> { self.lights.count > 0 }
      try_until -> { block.call(self) }, timeout: timeout, condition_interval: condition_interval do
        discover
      end
      self
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
    # @return [Array<String>] Tags that were purged
    def purge_unused_tags!
      context.purge_unused_tags!
    end

    # Blocks until all messages have been sent to the gateways
    # @param timeout: [Numeric] When specified, flush will wait `timeout:` seconds before throwing `Timeout::Error`
    # @raise [Timeout::Error] if `timeout:` was exceeded while waiting for send queue to flush
    # @return [void]
    def flush(timeout: nil)
      context.flush(timeout: timeout)
    end
  end
end
