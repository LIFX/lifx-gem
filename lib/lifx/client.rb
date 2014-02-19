require 'socket'
require 'timeout'
require 'yell'

module LIFX
  class Client
    LIFX_PORT = 56700
    def initialize(options = {})
      LIFX.const_set(:LOG, options[:logger] || default_logger)
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
        while sites.empty? || sites.none? { |s| s.gateway }
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

    def sites
      @networks.map(&:sites).flatten
    end

    def lights
      sites.map(&:lights).flatten
    end

    protected

    def default_logger
      Yell.new do |logger|
        logger.level = 'gte.warn'
        logger.adapter STDERR, format: '%d [%5L] %p/%t : %m'
      end
    end
  end
end
