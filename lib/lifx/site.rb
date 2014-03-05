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
      @threads << defer_lights_discovery
      @threads << initialize_timer_thread
      # @tag_manager.discover
    end

    def write(message)
      message.path.site_id = id
      @gateways.values.each do |gateway|
        gateway.write(message)
      end
    end

    def on_message(&block)
      @message_handler = block
    end

    def handle_message(message, ip, transport)
      logger.debug("<- #{self} #{transport}: #{message}")
      payload = message.payload
      case payload
      when Protocol::Device::StatePanGateway
        @gateways_mutex.synchronize do
          @gateways[message.device_id] ||= GatewayConnection.new
          @gateways[message.device_id].handle_message(message, ip, transport)
          @gateways[message.device_id].on_message do |*args|
            @message_handler.call(*args) if @message_handler
          end
        end
      when Protocol::Device::StateTime
        # Heartbeat
      when Protocol::Device::StateTagLabels
        @tag_manager.handle_message(message, ip, transport)
      else
        @message_handler.call(*args) if @message_handler
      end
      seen!
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
    end

    def scan_lights
      write(Message.new(path: ProtocolPath.new(tagged: true), payload: Protocol::Light::Get.new))
    end
  end
end
