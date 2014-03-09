require 'socket'
require 'timeout'
require 'yell'

require 'lifx/network_context'
require 'lifx/light_collection'

module LIFX
  class Client
    class << self
      def lan
        @lan ||= new
      end

      def virtual_bulb
        @virtual_bulb ||= begin
          @virtual_bulb_client = new(transport: :virtual_bulb)
          @virtual_bulb_client.discover
          @virtual_bulb_client.lights.first
        end
      end
    end

    extend Forwardable

    attr_reader :context
    def initialize(transport: :lan, cache_path: nil)
      @context = NetworkContext.new(transport: transport, cache_path: cache_path)
    end

    DISCOVERY_DEFAULT_TIMEOUT = 10
    def discover(timeout = DISCOVERY_DEFAULT_TIMEOUT)
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

    def_delegators :@context, :lights, :tags, :unused_tags, :purge_unused_tags!, :refresh, :flush
  end
end
