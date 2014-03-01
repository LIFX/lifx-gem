require 'socket'
require 'timeout'
require 'yell'

require 'lifx/network'

module LIFX
  class Client
    LIFX_PORT = 56700
    def initialize(logger: nil)
      LIFX.logger = logger if logger
      @networks = []
      Socket.ip_address_list.each do |ip|
        next unless ip.ipv4? && !ip.ipv4_loopback? && ip.ipv4_private?
        broadcast = ip.ip_address.sub(/\.\d+$/, '.255')
        @networks << Network.new(broadcast, LIFX_PORT)
      end
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

    def lights_hash
      sites.map(&:lights_hash).reduce({}) do |hash, lights_hash|
        hash.merge!(lights_hash)
      end
    end

    def lights
      LightCollection.new(scope: self)
    end
  end
end
