module LIFX
  class Transport
    attr_reader :host, :port

    def initialize(host, port, ignore_unpackable_messages: true)
      @host = host
      @port = port
      @ignore_unpackable_messages = ignore_unpackable_messages
    end

    def listen(&block)
      raise NotImplementedError
    end

    def write(message)
      raise NotImplementedError
    end

    def close
      raise NotImplementedError
    end

    def to_s
      %Q{#<#{self.class.name} #{host}:#{port}>}
    end
    alias_method :inspect, :to_s
  end
end

require 'lifx/transport/udp'
require 'lifx/transport/tcp'
