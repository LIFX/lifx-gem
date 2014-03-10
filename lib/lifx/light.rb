require 'lifx/seen'
require 'lifx/color'
require 'lifx/target'
require 'lifx/light_target'

module LIFX
  class Light
    include Seen
    include LightTarget
    include Logging

    attr_reader :context

    attr_reader :id, :site_id, :label, :color, :power, :dim, :tags_field

    def initialize(context:, id:, site_id: nil, label: nil)
      @context = context
      @id = id
      @site_id = site_id
      @label = label
      @power = nil
      @context.register_device(self)
    end

    def handle_message(message, ip, transport)
      payload = message.payload
      case payload
      when Protocol::Light::State
        @label      = payload.label.to_s
        @color      = Color.from_struct(payload.color.snapshot)
        @power      = payload.power
        @dim        = payload.dim
        @tags_field = payload.tags
        seen!
      when Protocol::Device::StatePower
        @power = payload.level
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

    def send_message(payload)
      context.send_message(target: Target.new(device_id: id, site_id: @site_id), payload: payload)
      self
    end

    def on?
      power_state == :on
    end

    def off?
      power_state == :off
    end

    def power_state
      case power
      when nil
        :unknown
      when 0
        :off
      else
        :on
      end
    end

    def add_tag(tag)
      context.add_tag_to_device(tag: tag, device: self)
      self
    end

    def remove_tag(tag)
      context.remove_tag_from_device(tag: tag, device: self)
      self
    end

    def tags
      context.tags_for_device(self)
    end
    
    MAX_LABEL_LENGTH = 32
    class LabelTooLong < ArgumentError; end
    def set_label(label)
      if label.length > MAX_LABEL_LENGTH
        raise LabelTooLong.new("Label length must be below or equal to #{MAX_LABEL_LENGTH}")
      end
      send_message(Protocol::Device::SetLabel.new(label: label))
    end

    def to_s
      %Q{#<LIFX::Light id=#{id} label=#{label.to_s} power=#{power_state}>}.force_encoding(Encoding.default_external)
    end
    alias_method :inspect, :to_s

    def <=>(other)
      raise ArgumentError.new("Comparison of #{self} with #{other} failed") unless other.is_a?(LIFX::Light)
      [label, id, 0] <=> [other.label, other.id, 0]
    end
  end
end
