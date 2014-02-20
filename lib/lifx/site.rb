require 'lifx/seen'
require 'lifx/timers'

module LIFX
  class Site
    include Seen
    include Timers

    attr_reader :id, :gateways

    def initialize(id)
      @id            = id
      @lights        = {}
      @lights_mutex  = Mutex.new
      @gateways      = {}
      @gateways_mutex = Mutex.new
      @threads       = []
      @threads << initialize_write_queue
      @threads << defer_lights_discovery
      @threads << initialize_timer_thread
      initialize_heartbeat
    end

    def write(params)
      message = Message.new(params)
      message.site = id
      @gateways_mutex.synchronize do 
        gateways.values.each do |gateway|
          gateway.write(message)
        end
      end
      # TODO: Handle socket errors
    end

    def queue_write(params)
      @queue << params
    end

    def on_message(message, ip, transport)
      LOG.debug("<- #{self} #{transport}: #{message}")
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        @gateways_mutex.synchronize do
          @gateways[message.device] ||= GatewayConnection.new(self, ip)
          @gateways[message.device].on_message(message, ip, transport)
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

    def flush
      # TODO: Add a timeout option
      while !@queue.empty?
        sleep(MINIMUM_TIME_BETWEEN_MESSAGE_SEND)
      end
    end

    def lights
      @lights.dup # So people can't modify internal representation
    end

    def to_s
      %Q{#<LIFX::Site id=#{id}>}
    end
    alias_method :inspect, :to_s

    def stop
      @threads.each do |thread|
        Thread.kill(thread)
      end
      @gateways.values.each do |gateway|
        gateway.close
      end
    end

    protected

    def defer_lights_discovery
      # We wait a bit so the TCP transport has a chance to connect
      Thread.new do
        while gateways.empty?
          sleep 0.1
        end
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

    STALE_LIGHT_THRESHOLD = LIGHT_STATE_REQUEST_INTERVAL * 3 # seconds
    def remove_stale_lights
      @lights_mutex.synchronize do
        stale_lights = lights.values.select { |light| light.age > STALE_LIGHT_THRESHOLD }
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
