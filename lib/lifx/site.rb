require 'lifx/seen'
require 'lifx/timers'

module LIFX
  class Site
    include Seen
    include Timers

    attr_reader :id, :gateway_id

    def initialize(id, udp_transport)
      @id            = id
      @udp_transport = udp_transport
      @lights        = {}
      @lights_mutex  = Mutex.new
      @threads       = []
      @threads << initialize_write_queue
      @threads << defer_lights_discovery
      @threads << initialize_timer_thread
      initialize_heartbeat
    end

    def write(params)
      message = Message.new(params)
      message.site = id
      LOG.debug("-> #{self} #{best_transport}: #{message}")
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
      LOG.debug("<- #{self} #{best_transport}: #{message}")
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        @gateway_id = message.device
        port = payload.port.snapshot
        if payload.service == Protocol::Device::Service::TCP &&
            port > 0 &&
            (!@tcp_transport || !@tcp_transport.connected?)

          @tcp_transport = Transport::TCP.new(ip, port)
          @tcp_transport.listen do |message, ip|
            on_message(message, ip, @tcp_transport)
          end
        end
      when Protocol::Device::StateTime
        # Heartbeat
      else
        @lights_mutex.synchronize do
          @lights[message.device] ||= Light.new(self)
          @lights[message.device].on_message(message, ip, transport)
        end
      end
      seen!
    end

    def gateway
      @lights[gateway_id]
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

    def to_s
      %Q{#<LIFX::Site id=#{id} host=#{best_transport.host} port=#{best_transport.port}>}
    end
    alias_method :inspect, :to_s

    def stop
      @threads.each do |thread|
        Thread.kill(thread)
      end
      if @tcp_transport
        @tcp_transport.close
      end
    end

    protected

    DISCOVERY_WAIT_TIME = 0.1

    def defer_lights_discovery
      # We wait a bit so the TCP transport has a chance to connect
      Thread.new do
        sleep(DISCOVERY_WAIT_TIME)
        initialize_lights
      end
    end

    LIGHT_STATE_REQUEST_INTERVAL = 30
    STALE_LIGHT_CHECK_INTERVAL   = 5
    def initialize_lights
      timers.every(LIGHT_STATE_REQUEST_INTERVAL) do
        scan_lights
      end.fire
      timers.every(STALE_LIGHT_CHECK_INTERVAL) do
        remove_stale_lights
      end
    end

    def scan_lights
      queue_write(payload: Protocol::Light::Get.new, tagged: true)
    end

    STALE_LIGHT_THRESHOLD = LIGHT_STATE_REQUEST_INTERVAL * 1.2 # seconds
    def remove_stale_lights
      @lights_mutex.synchronize do
        stale_lights = lights.select { |light| light.age > STALE_LIGHT_THRESHOLD }
        stale_lights.each do |light|
          LOG.info("#{self}: Removing #{light} due to age #{light.age}")
          @lights.delete(light.id)
        end
      end
    end

    MINIMUM_TIME_BETWEEN_MESSAGE_SEND = 0.2
    MAXIMUM_QUEUE_LENGTH = 100

    def initialize_write_queue
      @queue = SizedQueue.new(MAXIMUM_QUEUE_LENGTH)
      @last_write = Time.now
      Thread.new do
        loop do
          message = @queue.pop
          delay = [MINIMUM_TIME_BETWEEN_MESSAGE_SEND - (Time.now - @last_write), 0].max
          LOG.debug("#{self}: Sleeping for #{delay}")
          sleep(delay)
          write(message)
          @last_write = Time.now
        end
      end
    end

    HEARTBEAT_INTERVAL = 10
    def initialize_heartbeat
      timers.every(HEARTBEAT_INTERVAL) do
        queue_write(target: id, payload: Protocol::Device::GetTime.new)
      end
    end
  end
end
