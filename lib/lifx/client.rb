require 'socket'

module LIFX
  class Client
    LIFX_PORT = 56700

    def initialize
      @networks = []
      Socket.ip_address_list.each do |ip|
        next unless ip.ipv4? && !ip.ipv4_loopback? && ip.ipv4_private?
        broadcast = ip.ip_address.sub(/\.\d+$/, '.255')
        @networks << Network.new(broadcast, LIFX_PORT)
      end
    end

    DISCOVERY_DEFAULT_TIMEOUT = 3
    def discover(timeout = DISCOVERY_DEFAULT_TIMEOUT)
      @networks.each do |network|
        network.discover
      end
      sleep(timeout)
    end

    def sites
      @networks.map(&:sites).flatten
    end

    def lights
      sites.map(&:lights).flatten
    end
  end
end
