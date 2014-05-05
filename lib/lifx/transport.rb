require 'lifx/observable'

module LIFX
  # @api private
  class Transport
    include Logging
    include Observable

    attr_reader :host, :port

    def initialize(host, port, ignore_unpackable_messages: true)
      @host = host
      @port = port
      @ignore_unpackable_messages = ignore_unpackable_messages
    end

    def listen
      raise NotImplementedError
    end

    def write(message)
      raise NotImplementedError
    end

    def close
      remove_observers
    end

    def to_s
      %Q{#<#{self.class.name} #{host}:#{port}>}
    end
    alias_method :inspect, :to_s

    def observer_callback_definition
      {
        message_received: -> (message: nil, ip: nil, transport: nil) {},
        disconnected: -> {}
      }
    end
  end
end

require 'lifx/transport/udp'
require 'lifx/transport/tcp'
