require 'lifx/seen'
require 'lifx/color'

module LIFX
  class Light
    include Seen
    attr_reader :site

    attr_accessor :id, :label, :color, :power, :dim, :tags

    def initialize(site)
      @site = site
      @power = 0
    end

    def on_message(message, ip, transport)
      payload = message.payload
      @id    = message.device
      case payload
      when Protocol::Light::State
        @label = payload.label.to_s
        @color = Color.from_struct(payload.color.snapshot)
        @power = payload.power
        @dim   = payload.dim
        @tags  = payload.tags
        seen!
      when Protocol::Device::StatePower
        @power = payload.level
        queue_write(payload: Protocol::Light::Get.new) if !label
        seen!
      when Protocol::Device::StateLabel
        @label = payload.label.to_s
        seen!
      else
        LOG.warn("#{self}: Unhandled message: #{message}")
      end
    end

    def queue_write(params)
      site.queue_write(params.merge(target: id))
    end

    def refresh
      queue_write(payload: Protocol::Light::Get.new)
    end

    MSEC_PER_SEC   = 1000
    def set_color(color, duration = default_duration)
      queue_write(payload: Protocol::Light::Set.new(
        color: color.to_hsbk,
        duration: (duration * MSEC_PER_SEC).to_i,
        stream: 0,
      ))
    end

    MAX_LABEL_LENGTH = 32
    class LabelTooLong < ArgumentError; end
    def set_label(label)
      if label.length > MAX_LABEL_LENGTH
        raise LabelTooLong.new("Label length must be below or equal to #{MAX_LABEL_LENGTH}")
      end
      queue_write(payload: Protocol::Device::SetLabel.new(label: label))
    end

    def on?
      !off?
    end

    def off?
      power.zero?
    end

    def on!
      queue_write(payload: Protocol::Device::SetPower.new(level: 1))
    end

    def off!
      queue_write(payload: Protocol::Device::SetPower.new(level: 0))
    end

    def to_s
      %Q{#<LIFX::Light id=#{id} label=#{label} power=#{on? ? 'on' : 'off'}>}
    end
    alias_method :inspect, :to_s

    def <=>(other)
      raise ArgumentError.new("Comparison of #{self} with #{other} failed") unless other.is_a?(LIFX::Light)
      [label, id, 0] <=> [other.label, other.id, 0]
    end

    protected

    def build_hsbk(hue, saturation, brightness, kelvin)
      Protocol::Light::Hsbk.new(
        hue: (hue / 360.0 * UINT16_MAX).to_i,
        saturation: (saturation * UINT16_MAX).to_i,
        brightness: (brightness * UINT16_MAX).to_i,
        kelvin: kelvin.to_i
      )
    end

    def default_duration
      # TODO: Allow client-level configuration
      0.5
    end
  end
end
