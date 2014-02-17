module LIFX
  class Transport
    attr_reader :host, :port

    def initialize(host, port)
      @host = host
      @port = port
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

    def flush
      raise NotImplementedError
    end
  end
end

require 'lifx/transport/udp'
