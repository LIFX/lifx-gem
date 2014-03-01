require 'lifx/seen'
require 'lifx/color'
require 'lifx/light_target'

module LIFX
  class Light
    include Seen
    include LightTarget
    attr_reader :site

    attr_accessor :id, :label, :color, :power, :dim, :tags_field

    def initialize(site)
      @site = site
      @power = 0
    end

    def on_message(message, ip, transport)
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
        queue_write(payload: Protocol::Light::Get.new) if !label
        seen!
      when Protocol::Device::StateLabel
        @label = payload.label.to_s
        seen!
      when Protocol::Device::StateTags
        @tags_field = payload.tags
        seen!
      else
        LOG.warn("#{self}: Unhandled message: #{message}")
      end
    end

    def queue_write(params)
      site.queue_write(params.merge(target: id))
    end

    def on?
      !off?
    end

    def off?
      power.zero?
    end

    def add_tag(tag)
      site.add_tag_to_light(tag, self)
    end

    def remove_tag(tag)
      site.remove_tag_from_light(tag, self)
    end

    def tags
      site.tags_on_light(self)
    end

    def to_s
      %Q{#<LIFX::Light id=#{id} label=#{label.to_s} power=#{on? ? 'on' : 'off'}>}
    end
    alias_method :inspect, :to_s

    def <=>(other)
      raise ArgumentError.new("Comparison of #{self} with #{other} failed") unless other.is_a?(LIFX::Light)
      [label, id, 0] <=> [other.label, other.id, 0]
    end

    protected
    
    def default_duration
      # TODO: Allow client-level configuration
      0.5
    end
  end
end
