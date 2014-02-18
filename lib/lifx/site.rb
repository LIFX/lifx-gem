module LIFX
  class Site
    attr_reader :id, :gateway
    def initialize(id, udp_transport)
      @id = id
      @udp_transport = udp_transport
      @lights = {}
      initialize_write_queue
      defer_lights_discovery
    end

    def write(params)
      message = Message.new(params)
      message.site = id
      puts "-> #{best_transport.inspect}: #{message.inspect}"
      best_transport.write(message)
      # TODO: Handle socket errors
    end

    def queue_write(params)
      @queue << params
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
        @gateway ||= @lights[message.device] if message.device == message.site
      end
    end

    def lights
      @lights.values
    end

    def flush
      # TODO: Add a timeout option
      while !@queue.empty?
        sleep(MINIMUM_TIME_BETWEEN_MESSAGE_SEND)
      end
    end

    def inspect
      %Q{#<LIFX::Site id=#{id} host=#{best_transport.host} port=#{best_transport.port}>}
    end

    protected

    DISCOVERY_WAIT_TIME = 0.1

    def defer_lights_discovery
      # We wait a bit so the TCP transport has a chance to connect
      Thread.new do
        sleep(DISCOVERY_WAIT_TIME)
        discover_lights
      end
    end

    def discover_lights
      queue_write(payload: Protocol::Light::Get.new, tagged: true)
    end

    MINIMUM_TIME_BETWEEN_MESSAGE_SEND = 0.2
    MAXIMUM_QUEUE_LENGTH = 100

    def initialize_write_queue
      @queue = SizedQueue.new(MAXIMUM_QUEUE_LENGTH)
      @last_write = Time.now
      @writing_thread = Thread.new do
        loop do
          message = @queue.pop
          delay = [MINIMUM_TIME_BETWEEN_MESSAGE_SEND - (Time.now - @last_write), 0].max
          puts "Waiting #{delay} till next send"
          sleep(delay)
          write(message)
          @last_write = Time.now
        end
      end
    end
  end
end
