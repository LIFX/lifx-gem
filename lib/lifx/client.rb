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
    def initialize(ip: nil)
      if ip
        @network = Network.new(ip: ip)
      else
        @network = Network.new
      end
    end

    DISCOVERY_DEFAULT_TIMEOUT = 10
    def discover(timeout = DISCOVERY_DEFAULT_TIMEOUT)
      Timeout.timeout(timeout) do
        @network.discover
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
      @network.sites_hash
    end

    def sites
      sites_hash.values
    end

    def lights
      LightCollection.new(scope: self)
    end
  end
end
