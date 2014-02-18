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

    def inspect
      %Q{#<LIFX::Light id=#{id.unpack('H*').join} label=#{label} power=#{power.zero? ? 'off' : 'on'}>}
    end

  end
end
