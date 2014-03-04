require 'lifx/seen'
require 'lifx/color'
require 'lifx/light_target'

module LIFX
  class Light
    include Seen
    include LightTarget
    include Logging

    attr_reader :context

    attr_accessor :id, :label, :color, :power, :dim, :tags_field

    def initialize(context, id: nil, site_id: nil)
      @context = context
      @id = id
      @site_id = site_id
      @power = 0
      @context.register_device(self)
    end

    def handle_message(message, ip, transport)
      payload = message.payload
      @id    = message.device
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
        write(payload: Protocol::Light::Get.new) if !label
        seen!
      when Protocol::Device::StateLabel
        @label = payload.label.to_s
        seen!
      when Protocol::Device::StateTags
        @tags_field = payload.tags
        seen!
      else
        logger.warn("#{self}: Unhandled message: #{message}")
      end
    end

    def write(params)
      @context.send_to_device(params.merge(device: id))
      self
    end

    def on?
      !off?
    end

    def off?
      power.zero?
    end

    def add_tag(tag)
      site.add_tag_to_light(tag, self)
      self
    end

    def remove_tag(tag)
      site.remove_tag_from_light(tag, self)
      self
    end

    def tags
      site.tags_on_light(self)
    end

    def to_s
      %Q{#<LIFX::Light id=#{id} label=#{label.to_s} power=#{on? ? 'on' : 'off'}>}.force_encoding(Encoding.default_external)
    end
    alias_method :inspect, :to_s

    def <=>(other)
      raise ArgumentError.new("Comparison of #{self} with #{other} failed") unless other.is_a?(LIFX::Light)
      [label, id, 0] <=> [other.label, other.id, 0]
    end
  end
end
