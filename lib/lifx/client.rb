require 'socket'
require 'timeout'

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

    DISCOVERY_DEFAULT_TIMEOUT = 5
    def discover(timeout = DISCOVERY_DEFAULT_TIMEOUT)
      Timeout.timeout(timeout) do
        @networks.each do |network|
          network.discover
        end
        while sites.empty? || sites.none? { |s| s.gateway }
          sleep 0.1
        end
        sites
      end
    rescue Timeout::Error
      sites
    end

    def sites
      @networks.map(&:sites).flatten
    end

    def lights
      sites.map(&:lights).flatten
    end
  end
end
