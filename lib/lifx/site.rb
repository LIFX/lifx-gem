require 'lifx/seen'
require 'lifx/timers'
require 'lifx/gateway_connection'
require 'lifx/light'
require 'lifx/tag_manager'

module LIFX
  class Site
    include Seen
    include Timers
    include Logging
    
    attr_reader :id, :gateways, :tag_manager

    def initialize(id)
      @id            = id
      @lights        = {}
      @lights_mutex  = Mutex.new
      @gateways      = {}
      @gateways_mutex = Mutex.new
      @tag_manager   = TagManager.new(self)
      @threads       = []
      @threads << initialize_write_queue
      @threads << defer_lights_discovery
      @threads << initialize_timer_thread
      initialize_heartbeat
      @tag_manager.discover
    end

    def write(message)
      @gateways_mutex.synchronize do 
        gateways.values.each do |gateway|
          gateway.write(message)
        end
      end
      # TODO: Handle socket errors
    end

    def queue_write(params)
      message = Message.new(params)
      message.site = id
      @queue << message
    end

    def on_message(message, ip, transport)
      logger.debug("<- #{self} #{transport}: #{message}")
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        @gateways_mutex.synchronize do
          @gateways[message.device] ||= GatewayConnection.new(self, ip)
          @gateways[message.device].on_message(message, ip, transport)
        end
      when Protocol::Device::StateTime
        # Heartbeat
      when Protocol::Device::StateTagLabels
        @tag_manager.on_message(message, ip, transport)
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

    def lights_hash
      @lights.dup # So people can't modify internal representation
    end

    def lights
      lights_hash.values
    end

    def tags
      @tag_manager.tags
    end

    def tags_on_light(light)
      @tag_manager.tags_on_light(light)
    end

    def add_tag_to_light(tag, light)
      @tag_manager.add_tag_to_light(tag, light)
    end

    def remove_tag_from_light(tag, light)
      @tag_manager.remove_tag_from_light(tag, light)
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
        stale_lights = lights.select { |light| light.age > STALE_LIGHT_THRESHOLD }
        stale_lights.each do |light|
          logger.info("#{self}: Removing #{light} due to age #{light.age}")
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
          logger.debug("#{self}: Sleeping for #{delay}")
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
