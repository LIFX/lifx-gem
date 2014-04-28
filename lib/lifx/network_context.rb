require 'lifx/timers'
require 'lifx/transport_manager'
require 'lifx/routing_manager'
require 'lifx/tag_manager'
require 'lifx/light'
require 'lifx/protocol_path'
require 'lifx/timers'

module LIFX
  class NetworkContext
    include Logging
    include Utilities
    include RequiredKeywordArguments
    include Timers
    extend Forwardable

    # NetworkContext stores lights and ties together TransportManager, TagManager and RoutingManager
    attr_reader :transport_manager, :tag_manager, :routing_manager

    def initialize(transport_manager: required!('transport_manager'))
      @devices = {}

      @transport_manager = transport_manager
      @transport_manager.context = self
      @transport_manager.add_observer(self) do |message: nil, ip: nil, transport: nil|
        handle_message(message, ip, transport)
      end

      reset!

      @threads = []
      @threads << initialize_timer_thread
    end

    def discover
      @transport_manager.discover
    end

    def refresh
      @routing_manager.refresh
    end

    def reset!
      @routing_manager = RoutingManager.new(context: self)
      @tag_manager = TagManager.new(context: self, tag_table: @routing_manager.tag_table)
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
    def send_message(target: required!(:target), payload: required!(:payload), acknowledge: false)
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

    def within_sync?
      !!Thread.current[:sync_enabled]
    end
    protected :within_sync?

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
        light = gateways.sample
        time = light && light.time
      end

      delay = (messages.count + 1) * (1.0 / message_rate)
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
      return if device.site_id == NULL_SITE_ID
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

    def to_s
      %Q{#<LIFX::NetworkContext transport_manager=#{transport_manager}>}
    end
    alias_method :inspect, :to_s

    protected

    def handle_message(message, ip, transport)
      logger.debug("<- #{self} #{transport}: #{message}")

      @routing_manager.update_from_message(message)
      if !message.tagged?
        if @devices[message.device_id].nil? && message.payload.is_a?(Protocol::Light::State)
          device = Light.new(context: self, id: message.device_id, site_id: message.site_id)
        end
        device = @devices[message.device_id]
        return if !device # Virgin bulb
        device.handle_message(message, ip, transport)
      end
    end
  end
end
