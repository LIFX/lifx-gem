module LIFX
  class Light
    attr_reader :site

    attr_accessor :id, :label, :color, :power, :dim, :tags

    def initialize(site)
      @site = site
    end

    def on_message(message, ip, transport)
      payload = message.payload
      case payload
      when Protocol::Light::State
        @id    = message.device
        @label = payload.label
        @color = payload.color
        @power = payload.power
        @dim   = payload.dim
        @tags  = payload.tags
      end
    end

    def write(params)
      site.write(params.merge(target: id))
    end

    UINT16_MAX = 65_535
    MSEC_PER_SEC = 1000
    DEFAULT_KELVIN = 3500
    def set_hsbk(hue, saturation, brightness, kelvin, duration = default_duration)
      hsbk = Protocol::Light::Hsbk.new(
        hue: (hue / 360.0 * UINT16_MAX).to_i,
        saturation: (saturation * UINT16_MAX).to_i,
        brightness: (brightness * UINT16_MAX).to_i,
        kelvin: kelvin.to_i
      )
      duration = (duration * MSEC_PER_SEC).to_i
      write(payload: Protocol::Light::Set.new(
        stream: 0,
        duration: duration,
        color: hsbk)
      )
    end

    def set_hsb(hue, saturation, brightness, duration = default_duration)
      set_hsbk(hue, saturation, brightness, DEFAULT_KELVIN, duration)
    end

    def set_white(brightness = 1, kelvin = DEFAULT_KELVIN, duration = default_duration)
      set_hsbk(0, 0, brightness, kelvin, duration)
    end

    def on!
      write(payload: Protocol::Device::SetPower.new(level: 1))
    end

    def off!
      write(payload: Protocol::Device::SetPower.new(level: 0))
    end

    def inspect
      %Q{#<LIFX::Light id=#{id.unpack('H*').join} label=#{label} power=#{power.zero? ? 'off' : 'on'}>}
    end

    protected

    def default_duration
      # TODO: Allow client-level configuration
      0.5
    end
  end
end
