module LIFX
  class Site
    attr_reader :id
    def initialize(id, udp_transport)
      @id = id
      @udp_transport = udp_transport
    end

    def write(params)
      message = Message.new(params)
      message.site = id
      p "Best transport:#{best_transport}"
      best_transport.write(message)
      # TODO: Handle socket errors
    end

    def best_transport
      if @tcp_transport
        # TODO: Check if connection still alive
        @tcp_transport
      else
        @udp_transport
      end
    end

    def on_message(message, ip)
      puts "#{@tcp_transport.inspect}: #{message.inspect}"
      case message.payload
      when Protocol::Device::StatePanGateway
        if message.payload.service == Protocol::Device::Service::TCP &&
            message.payload.port > 0 &&
            !@tcp_transport

          @tcp_transport = Transport::TCP.new(ip, message.payload.port.snapshot)
          @tcp_transport.listen do |message, ip|
            on_message(message, ip)
          end
        end
      end
    end
  end
end
