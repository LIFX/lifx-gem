require 'socket'
require 'timeout'

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
        @lan ||= new(transport_manager: TransportManager::LAN.new)
      end
    end

    extend Forwardable
    include Utilities

    # Refers to the client's network context.
    # @return [NetworkContext] Enclosed network context
    attr_reader :context

    # @param transport_manager: [TransportManager] Specify the {TransportManager}
    def initialize(transport_manager: required!('transport_manager'))
      @context = NetworkContext.new(transport_manager: transport_manager)
    end

    # Default timeout in seconds for discovery
    DISCOVERY_DEFAULT_TIMEOUT = 10

    # This method tells the {NetworkContext} to look for devices asynchronously.
    # @return [Client] self
    def discover
      @context.discover
    end

    class DiscoveryTimeout < Timeout::Error; end
    # This method tells the {NetworkContext} to look for devices, and will block
    # until there's at least one device.
    #
    # @example Wait until at least three lights have been found
    #   client.discover! { |c| c.lights.count >= 3 }
    # 
    # @param timeout: [Numeric] How long to try to wait for before returning
    # @param condition_interval: [Numeric] Seconds between evaluating the block
    # @yield [Client] This block is evaluated every `condition_interval` seconds. If true, method returns. If no block is supplied, it will block until it finds at least one light.
    # @raise [DiscoveryTimeout] If discovery times out
    # @return [Client] self
    def discover!(timeout: DISCOVERY_DEFAULT_TIMEOUT, condition_interval: 0.1, &block)
      block ||= -> { self.lights.count > 0 }
      try_until -> { block.arity == 1 ? block.call(self) : block.call },
        timeout: timeout,
        timeout_exception: DiscoveryTimeout,
        condition_interval: condition_interval,
        action_interval: 1 do
        discover
        refresh
      end
      self
    end

    # Sends a request to refresh devices and tags.
    # @return [void]
    def refresh
      @context.refresh
    end

    # This method takes a block consisting of multiple asynchronous color or power changing targets
    # and it will try to schedule them so they run at the same time.
    #
    # You cannot nest `sync` calls, nor call synchronous methods inside a `sync` block.
    #
    # Due to messaging rate constraints, the amount of messages determine the delay before 
    # the commands are executed. This method also assumes all the lights have the same time.
    # @example This example sets all the lights to a random colour at the same time.
    #   client.sync do
    #     client.lights.each do |light|
    #       light.set_color(rand(4) * 90, 1, 1)
    #     end
    #   end
    #
    # @note This method is in alpha and might go away. Use tags for better group messaging.
    # @yield Block of commands to synchronize
    # @return [Float] Number of seconds until commands are executed
    def sync(&block)
      @context.sync(&block)
    end

    # This is the same as {#sync}, except it will block until the commands have been executed.
    # @see #sync
    # @return [Float] Number of seconds slept
    def sync!(&block)
      sync(&block).tap do |delay|
        sleep(delay)
      end
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

    # Stops everything and cleans up.
    def stop
      context.stop
    end
  end
end
