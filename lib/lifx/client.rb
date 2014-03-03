require 'socket'
require 'timeout'
require 'yell'

require 'lifx/network'
require 'lifx/light_collection'

module LIFX
  class Client
    def self.instance
      @instance ||= new
    end

    LIFX_PORT = 56700
    def initialize
      @networks = []
      @networks << Network.new
    end

    DISCOVERY_DEFAULT_TIMEOUT = 10
    def discover(timeout = DISCOVERY_DEFAULT_TIMEOUT)
      Timeout.timeout(timeout) do
        @networks.each do |network|
          network.discover
        end
        while sites.empty?
          sleep 0.1
        end
        sites
      end
    rescue Timeout::Error
      sites
    end

    def flush
      threads = sites.map do |site|
        Thread.new do
          site.flush
        end
      end
      threads.each do |thread|
        thread.join
      end
    end

    def sites_hash
      @networks.map(&:sites_hash).reduce({}) do |hash, sites_hash|
        hash.merge!(sites_hash)
      end
    end

    def sites
      sites_hash.values
    end

    def lights
      LightCollection.new(scope: self)
    end
  end
end
