require 'lifx/seen'
require 'lifx/color'
require 'lifx/target'
require 'lifx/light_target'

module LIFX
  # LIFX::Light represents a Light device
  class Light
    include Seen
    include LightTarget
    include Logging

    # @return [NetworkContext] NetworkContext the Light belongs to
    attr_reader :context

    # @return [String] Device ID
    attr_reader :id

    # @return [String] Label of the device
    attr_reader :label

    # @return [Color] Last known color of the Light
    attr_reader :color

    # @param context: [NetworkContext] {NetworkContext} the Light belongs to
    # @param id: [String] Device ID of the Light
    # @param site_id: [String] Site ID of the Light. Avoid using when possible.
    # @param label: [String] Label of Light to prepopulate
    def initialize(context:, id:, site_id: nil, label: nil)
      @context = context
      @id = id
      @site_id = site_id
      @label = label
      @power = nil
      @context.register_device(self)
    end

    # Handles updating the internal state of the Light from incoming
    # protocol messages.
    # @api private
    def handle_message(message, ip, transport)
      payload = message.payload
      case payload
      when Protocol::Light::State
        @label      = payload.label.to_s
        @color      = Color.from_struct(payload.color.snapshot)
        @power      = payload.power.to_i
        @tags_field = payload.tags
        seen!
      when Protocol::Device::StatePower
        @power = payload.level.to_i
        send_message(Protocol::Light::Get.new) if !label
        seen!
      when Protocol::Device::StateLabel
        @label = payload.label.to_s
        seen!
      when Protocol::Device::StateTags
        @tags_field = payload.tags
        seen!
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
      @tags_field
    end

    # Sends a message to the Light
    # @param payload [Protocol::Payload] the payload to send
    # @return [Light] returns self for chaining
    def send_message(payload)
      context.send_message(target: Target.new(device_id: id, site_id: @site_id), payload: payload)
      self
    end

    # @return [Boolean] Returns true if device is on
    def on?
      power == :on
    end

    # @return [Boolean] Returns true if device is off
    def off?
      power == :off
    end

    # @return [:unknown, :off, :on] Light power state
    def power
      case @power
      when nil
        :unknown
      when 0
        :off
      else
        :on
      end
    end

    # Adds a tag to the Light
    # @param tag [String] The tag to add
    # @return [Light] self
    def add_tag(tag)
      context.add_tag_to_device(tag: tag, device: self)
      self
    end

    # Removes a tag from the Light
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
      send_message(Protocol::Device::SetLabel.new(label: label))
      self
    end

    # Returns a nice string representation of the Light
    def to_s
      %Q{#<LIFX::Light id=#{id} label=#{label.to_s} power=#{power}>}.force_encoding(Encoding.default_external)
    end
    alias_method :inspect, :to_s

    # Compare current Light to another light
    # @param other [Light]
    # @return [-1, 0, 1] Comparison value
    def <=>(other)
      raise ArgumentError.new("Comparison of #{self} with #{other} failed") unless other.is_a?(LIFX::Light)
      [label, id, 0] <=> [other.label, other.id, 0]
    end
  end
end
