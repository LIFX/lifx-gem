require 'lifx/timers'
require 'lifx/transport_manager'
require 'lifx/routing_manager'
require 'lifx/tag_manager'
require 'lifx/light'
require 'lifx/protocol_path'

module LIFX
  class NetworkContext
    include Timers
    include Logging
    include Utilities
    extend Forwardable

    # NetworkContext stores lights and ties together TransportManager, TagManager and RoutingManager
    attr_reader :transport_manager, :tag_manager, :routing_manager
    
    def initialize(transport: :lan)
      @devices = {}

      @transport_manager = case transport
      when :lan
        TransportManager::LAN.new
      else
        raise ArgumentError.new("Unknown transport method: #{transport}")
      end
      @transport_manager.add_observer(self) do |message:, ip:, transport:|
        handle_message(message, ip, transport)
      end

      @routing_manager = RoutingManager.new(context: self)
      @tag_manager = TagManager.new(context: self, tag_table: @routing_manager.tag_table)
      @threads = []
      @threads << initialize_timer_thread
      initialize_message_rate_updater
    end

    def discover
      @transport_manager.discover
      @routing_manager.refresh
    end

    def stop
      @transport_manager.stop
      @threads.each do |thread|
        Thread.kill(thread)
      end
    end

    # Sends a message to their destination(s)
    # @param target: [Target] Target of the message
    # @param payload: [Protocol::Payload] Message payload
    # @param acknowledge: [Boolean] If recipients must acknowledge with a response
    def send_message(target:, payload:, acknowledge: false)
      paths = @routing_manager.resolve_target(target)

      messages = paths.map do |path|
        Message.new(path: path, payload: payload, acknowledge: acknowledge)
      end

      if within_sync?
        Thread.current[:sync_messages].push(*messages)
        return
      end

      messages.each do |message|
        @transport_manager.write(message)
      end
    end

    protected def within_sync?
      !!Thread.current[:sync_enabled]
    end

    # Synchronize asynchronous set_color, set_waveform and set_power messages to multiple devices.
    # You cannot use synchronous methods in the block
    # @note This is alpha
    # @yield Block to synchronize commands in
    # @return [Float] Delay before messages are executed
    def sync(&block)
      if within_sync?
        raise "You cannot nest sync"
      end
      messages = Thread.new do
        Thread.current[:sync_enabled] = true
        Thread.current[:sync_messages] = messages = []
        block.call
        Thread.current[:sync_enabled] = false
        messages
      end.join.value

      time = nil
      try_until -> { time } do
        light = lights.to_a.sample
        time = light && light.time
      end

      delay = messages.count * (1 / 5.0) + 0.25
      at_time = ((time.to_f + delay) * 1_000_000_000).to_i
      messages.each do |m|
        m.at_time = at_time
        @transport_manager.write(m)
      end
      flush
      delay
    end

    def flush(**options)
      @transport_manager.flush(**options)
    end

    def register_device(device)
      device_id = device.id
      @devices[device_id] = device # What happens when there's already one registered?
    end

    def lights
      LightCollection.new(context: self)
    end

    def all_lights
      @devices.values
    end

    # Tags

    def_delegators :@tag_manager, :tags,
                                  :unused_tags,
                                  :purge_unused_tags!,
                                  :add_tag_to_device,
                                  :remove_tag_from_device

    def tags_for_device(device)
      @routing_manager.tags_for_device_id(device.id)
    end

    protected

    def handle_message(message, ip, transport)
      logger.debug("<- #{self} #{transport}: #{message}")

      @routing_manager.update_from_message(message)
      if !message.tagged?
        if @devices[message.device_id].nil?
          device = Light.new(context: self, id: message.device_id, site_id: message.site_id)
          register_device(device)
        end
        device = @devices[message.device_id]
        device.handle_message(message, ip, transport)
      end
    end

    def gateway_connections
      transport_manager.gateways.map(&:values).flatten
    end

    def initialize_message_rate_updater
      timers.every(5) do
        @message_rate = lights.all? do |light|
          light.mesh_firmware >= '1.2' && light.wifi_firmware >= '1.2'
        end ? 50 : 5
        gateway_connections.each do |connection|
          connection.set_message_rate(@message_rate)
        end
      end
    end

    DEFAULT_MESSAGING_RATE = 5 # per second
    def message_rate
      @message_rate || 5
    end
  end
end
