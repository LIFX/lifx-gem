require 'lifx/seen'
require 'lifx/color'
require 'lifx/target'
require 'lifx/light_target'
require 'lifx/firmware'

module LIFX
  # LIFX::Light represents a Light device
  class Light
    include Seen
    include LightTarget
    include Logging
    include Utilities
    include RequiredKeywordArguments

    # @return [NetworkContext] NetworkContext the Light belongs to
    attr_reader :context

    # @return [String] Device ID
    attr_reader :id

    # @param context: [NetworkContext] {NetworkContext} the Light belongs to
    # @param id: [String] Device ID of the Light
    # @param site_id: [String] Site ID of the Light. Avoid using when possible.
    # @param label: [String] Label of Light to prepopulate
    def initialize(context: required!(:context), id: id, site_id: nil, label: nil)
      @context = context
      @id = id
      @site_id = site_id
      @label = label
      @power = nil
      @message_hooks = Hash.new { |h, k| h[k] = [] }
      @context.register_device(self)
      @message_signal = ConditionVariable.new

      add_hooks
    end

    # Handles updating the internal state of the Light from incoming
    # protocol messages.
    # @api private
    def handle_message(message, ip, transport)
      payload = message.payload

      @message_hooks[payload.class].each do |hook|
        hook.call(payload)
      end
      @message_signal.broadcast
    end

    # Adds a block to be run when a payload of class `payload_class` is received
    # @param payload_class [Class] Payload type to execute block on
    # @param &hook [Proc] Hook to run
    # @api private
    # @return [void]
    def add_hook(payload_class, hook_arg = nil, &hook_block)
      hook = block_given? ? hook_block : hook_arg
      if !hook || !hook.is_a?(Proc)
        raise "MUst pass a proc either as an argument or a block"
      end
      @message_hooks[payload_class] << hook
    end

    # Removes a hook added by {#add_hook}
    # @param payload_class [Class] Payload type to delete hook from
    # @param hook [Proc] The original hook passed into {#add_hook}
    # @api private
    # @return [void]
    def remove_hook(payload_class, hook)
      @message_hooks[payload_class].delete(hook)
    end

    # Returns the color of the device.
    # @param refresh: [Boolean] If true, will request for current color
    # @param fetch: [Boolean] If false, it will not request current color if it's not cached
    # @return [Color] Color
    def color(refresh: false, fetch: true)
      @color = nil if refresh
      send_message!(Protocol::Light::Get.new, wait_for: Protocol::Light::State) if fetch && !@color
      @color
    end

    # Returns the label of the light
    # @param refresh: [Boolean] If true, will request for current label
    # @param fetch: [Boolean] If false, it will not request current label if it's not cached
    # @return [String, nil] Label
    def label(refresh: false, fetch: true)
      @label = nil if refresh
      send_message!(Protocol::Light::Get.new, wait_for: Protocol::Light::State) if fetch && !@label
      @label
    end

    MAX_LABEL_LENGTH = 32
    class LabelTooLong < ArgumentError; end

    # Sets the label of the light
    # @param label [String] Desired label
    # @raise [LabelTooLong] if label is greater than {MAX_LABEL_LENGTH}
    # @return [Light] self
    def set_label(label)
      if label.length > MAX_LABEL_LENGTH
        raise LabelTooLong.new("Label length must be below or equal to #{MAX_LABEL_LENGTH}")
      end
      while self.label != label
        send_message!(Protocol::Device::SetLabel.new(label: label), wait_for: Protocol::Device::StateLabel)
      end
      self
    end

    # Set the power state to `state` synchronously.
    # @param state [:on, :off]
    # @return [Light, LightCollection] self for chaining
    def set_power!(state)
      level = case state
      when :on
        1
      when :off
        0
      else
        raise ArgumentError.new("Must pass in either :on or :off")
      end
      send_message!(Protocol::Device::SetPower.new(level: level), wait_for: Protocol::Device::StatePower) do |payload|
        if level == 0
          payload.level == 0
        else
          payload.level > 0
        end
      end
      self
    end

    # Turns the light(s) on synchronously
    # @return [Light, LightCollection] self for chaining
    def turn_on!
      set_power!(:on)
    end

    # Turns the light(s) off synchronously
    # @return [Light, LightCollection]
    def turn_off!
      set_power!(:off)
    end

    # @see #power
    # @return [Boolean] Returns true if device is on
    def on?(refresh: false, fetch: true)
      power(refresh: refresh, fetch: fetch) == :on
    end

    # @see #power
    # @return [Boolean] Returns true if device is off
    def off?(refresh: false, fetch: true)
      power(refresh: refresh, fetch: fetch) == :off
    end

    # @param refresh: see #label
    # @param fetch: see #label
    # @return [:unknown, :off, :on] Light power state
    def power(refresh: false, fetch: true)
      @power = nil if refresh
      send_message!(Protocol::Light::Get.new, wait_for: Protocol::Light::State) if !@power && fetch
      case @power
      when nil
        :unknown
      when 0
        :off
      else
        :on
      end
    end

    # Returns the local time of the light
    # @return [Time]
    def time
      send_message!(Protocol::Device::GetTime.new, wait_for: Protocol::Device::StateTime) do |payload|
        Time.at(payload.time.to_f / NSEC_IN_SEC)
      end
    end

    # Returns the difference between the device time and time on the current machine
    # Positive values means device time is further in the future.
    # @return [Float]
    def time_delta
      device_time = time
      delta = device_time - Time.now
    end

    # Pings the device and measures response time.
    # @return [Float] Latency from sending a message to receiving a response.
    def latency
      start = Time.now.to_f
      send_message!(Protocol::Device::GetTime.new, wait_for: Protocol::Device::StateTime)
      Time.now.to_f - start
    end

    # Returns the mesh firmware details
    # @api private
    # @return [Hash] firmware details
    def mesh_firmware(fetch: true)
      @mesh_firmware ||= begin
        send_message!(Protocol::Device::GetMeshFirmware.new,
          wait_for: Protocol::Device::StateMeshFirmware) do |payload|
          Firmware.new(payload)
        end if fetch
      end
    end

    # Returns the wifi firmware details
    # @api private
    # @return [Hash] firmware details
    def wifi_firmware(fetch: true)
      @wifi_firmware ||= begin
        send_message!(Protocol::Device::GetWifiFirmware.new,
          wait_for: Protocol::Device::StateWifiFirmware) do |payload|
          Firmware.new(payload)
        end if fetch
      end
    end

    # Returns the temperature of the device
    # @return [Float] Temperature in Celcius
    def temperature
      send_message!(Protocol::Light::GetTemperature.new,
          wait_for: Protocol::Light::StateTemperature) do |payload|
        payload.temperature / 100.0
      end
    end

    # Returns mesh network info
    # @api private
    # @return [Hash] Mesh network info
    def mesh_info
      send_message!(Protocol::Device::GetMeshInfo.new,
          wait_for: Protocol::Device::StateMeshInfo) do |payload|
        {
          signal: payload.signal, # This is in Milliwatts
          tx: payload.tx,
          rx: payload.rx
        }
      end
    end

    # Returns wifi network info
    # @api private
    # @return [Hash] wifi network info
    def wifi_info
      send_message!(Protocol::Device::GetWifiInfo.new,
          wait_for: Protocol::Device::StateWifiInfo) do |payload|
        {
          signal: payload.signal, # This is in Milliwatts
          tx: payload.tx,
          rx: payload.rx
        }
      end
    end

    # Returns version info
    # @api private
    # @return [Hash] version info
    def version
      send_message!(Protocol::Device::GetVersion.new,
         wait_for: Protocol::Device::StateVersion) do |payload|
        {
          vendor: payload.vendor,
          product: payload.product,
          version: payload.version
        }
      end
    end

    # Return device uptime
    # @api private
    # @return [Float] Device uptime in seconds
    def uptime
      send_message!(Protocol::Device::GetInfo.new,
         wait_for: Protocol::Device::StateInfo) do |payload|
        payload.uptime.to_f / NSEC_IN_SEC
      end
    end

    # Return device last downtime
    # @api private
    # @return [Float] Device's last downtime in secodns
    def last_downtime
      send_message!(Protocol::Device::GetInfo.new,
         wait_for: Protocol::Device::StateInfo) do |payload|
        payload.downtime.to_f / NSEC_IN_SEC
      end
    end

    # Returns the `site_id` the Light belongs to.
    # @api private
    # @return [String]
    def site_id
      if @site_id.nil?
        # FIXME: This is ugly.
        context.routing_manager.routing_table.site_id_for_device_id(id)
      else
        @site_id
      end
    end

    # Returns the tags uint64 bitfield for protocol use.
    # @api private
    # @return [Integer]
    def tags_field
      try_until -> { @tags_field } do
        send_message(Protocol::Device::GetTags.new)
      end
      @tags_field
    end

    # Add tag to the Light
    # @param tag [String] The tag to add
    # @return [Light] self
    def add_tag(tag)
      context.add_tag_to_device(tag: tag, device: self)
      self
    end

    # Remove tag from the Light
    # @param tag [String] The tag to remove
    # @return [Light] self
    def remove_tag(tag)
      context.remove_tag_from_device(tag: tag, device: self)
      self
    end

    # Returns the tags that are associated with the Light
    # @return [Array<String>] tags
    def tags
      context.tags_for_device(self)
    end

    # Returns whether the light is a gateway
    # @api private
    def gateway?
      context.transport_manager.gateways.include?(self)
    end

    # Returns a nice string representation of the Light
    # @return [String]
    def to_s
      %Q{#<LIFX::Light id=#{id} label=#{label(fetch: false)} power=#{power(fetch: false)}>}.force_encoding(Encoding.default_external)
    end
    alias_method :inspect, :to_s

    # Compare current Light to another light
    # @param other [Light]
    # @return [-1, 0, 1] Comparison value
    def <=>(other)
      raise ArgumentError.new("Comparison of #{self} with #{other} failed") unless other.is_a?(LIFX::Light)
      [label, id, 0] <=> [other.label, other.id, 0]
    end

    # Queues a message to be sent the Light
    # @param payload [Protocol::Payload] the payload to send
    # @param acknowledge: [Boolean] whether the device should respond
    # @param at_time: [Integer] Unix epoch in milliseconds to run the payload. Only applicable to certain payload types.
    # @return [Light] returns self for chaining
    def send_message(payload, acknowledge: true, at_time: nil)
      context.send_message(target: Target.new(device_id: id, site_id: @site_id), payload: payload, acknowledge: acknowledge, at_time: nil)
    end

    # An exception for when synchronous messages take too long to receive a response
    class MessageTimeout < TimeoutError
      attr_accessor :device
    end

    # Queues a message to be sent to the Light and waits for a response
    # @param payload [Protocol::Payload] the payload to send
    # @param wait_for: [Class] the payload class to wait for
    # @param wait_timeout: [Numeric] wait timeout
    # @param block: [Proc] the block that is executed when the expected `wait_for` payload comes back. If the return value is false or nil, it will try to send the message again.
    # @return [Object] the truthy result of `block` is returned.
    # @raise [MessageTimeout] if the device doesn't respond in time
    def send_message!(payload, wait_for: wait_for, wait_timeout: 3, &block)
      if Thread.current[:sync_enabled]
        raise "Cannot use synchronous methods inside a sync block"
      end

      result = nil
      begin
        block ||= Proc.new { |msg| true }
        proc = -> (payload) {
          result = block.call(payload)
        }
        add_hook(wait_for, proc)
        try_until -> { result }, signal: @message_signal do
          send_message(payload)
        end
        result
      rescue TimeoutError
        backtrace = caller_locations(2).map { |c| c.to_s }
        caller_method = caller_locations(2, 1).first.label
        ex = MessageTimeout.new("#{caller_method}: Timeout exceeded waiting for response from #{self}")
        ex.device = self
        ex.set_backtrace(backtrace)
        raise ex
      ensure
        remove_hook(wait_for, proc)
      end
    end

    protected

    def add_hooks
      add_hook(Protocol::Device::StateLabel) do |payload|
        @label = payload.label.to_s
        seen!
      end

      add_hook(Protocol::Light::State) do |payload|
        @label      = payload.label.snapshot
        @color      = Color.from_struct(payload.color.snapshot)
        @power      = payload.power.to_i
        @tags_field = payload.tags
        seen!
      end

      add_hook(Protocol::Device::StateTags) do |payload|
        @tags_field = payload.tags
        seen!
      end

      add_hook(Protocol::Device::StatePower) do |payload|
        @power = payload.level.to_i
        seen!
      end

      add_hook(Protocol::Device::StateMeshFirmware) do |payload|
        @mesh_firmware = Firmware.new(payload)
        seen!
      end

      add_hook(Protocol::Device::StateWifiFirmware) do |payload|
        @wifi_firmware = Firmware.new(payload)
        seen!
      end
    end
  end
end
