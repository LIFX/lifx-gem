module LIFX
  class Site
    attr_reader :id
    def initialize(id, udp_transport)
      @id = id
      @udp_transport = udp_transport
      @lights = {}
      defer_lights_discovery
    end

    def write(params)
      message = Message.new(params)
      message.site = id
      puts "-> #{best_transport.inspect}: #{message.inspect}"
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

    def on_message(message, ip, transport)
      puts "<- #{transport.inspect}: #{message.inspect}"
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        port = payload.port.snapshot
        if payload.service == Protocol::Device::Service::TCP &&
            port > 0 &&
            !@tcp_transport

          @tcp_transport = Transport::TCP.new(ip, port)
          @tcp_transport.listen do |message, ip|
            on_message(message, ip, @tcp_transport)
          end
        end
      when Protocol::Light::State
        @lights[message.device] ||= Light.new(self)
        @lights[message.device].on_message(message, ip, transport)
      end
    end

    def lights
      @lights.values
    end

    def inspect
      %Q{#<LIFX::Site id=#{id.unpack('H*').join} host=#{best_transport.host} port=#{best_transport.port}>}
    end

    protected

    DISCOVERY_WAIT_TIME = 0.1
    def defer_lights_discovery
      Thread.new do
        sleep(DISCOVERY_WAIT_TIME)
        discover_lights
      end
    end

    def discover_lights
      write(payload: Protocol::Light::Get.new, tagged: true)
    end
  end
end
