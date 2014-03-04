require 'socket'
require 'timeout'
require 'yell'

require 'lifx/network_context'
require 'lifx/light_collection'

module LIFX
  class Client
    def self.instance
      @instance ||= new
    end

    LIFX_PORT = 56700
    def initialize(ip: nil)
      if ip
        @network_context = NetworkContext.new(ip: ip)
      else
        @network_context = NetworkContext.new
      end
    end

    DISCOVERY_DEFAULT_TIMEOUT = 10
    def discover(timeout = DISCOVERY_DEFAULT_TIMEOUT)
      Timeout.timeout(timeout) do
        @network_context.discover
        while lights.empty?
          sleep 0.1
        end
        lights
      end
    rescue Timeout::Error
      lights
    end

    def flush
      @network_context.flush
    end

    def lights
      @network_context.lights
    end
  end
end
