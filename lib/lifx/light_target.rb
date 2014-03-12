module LIFX
  # LightTarget is a module that contains Light commands that can work
  # with either a single {Light} or multiple Lights via a {LightCollection}
  module LightTarget
    MSEC_PER_SEC   = 1000

    # Attempts to set the color of the light(s) to `color`
    # @param color [Color] The color to be set
    # @param duration: [Numeric] Transition time in seconds
    # @return [Light, LightCollection] self for chaining
    def set_color(color, duration: LIFX::Config.default_duration)
      send_message(Protocol::Light::Set.new(
        color: color.to_hsbk,
        duration: (duration * MSEC_PER_SEC).to_i,
        stream: 0,
      ))
      self
    end

    # Attempts to set the power state to `value`
    # @param value [0, 1] 0 for off, 1 for on
    # @return [Light, LightCollection] self for chaining
    def set_power(value)
      send_message(Protocol::Device::SetPower.new(level: value))
      self
    end

    # Attempts to turn the light(s) on
    # @return [Light, LightCollection] self for chaining
    def turn_on
      set_power(1)
    end

    # Attempts to turn the light(s) off
    # @return [Light, LightCollection] self for chaining
    def turn_off
      set_power(0)
    end

    # Requests light(s) to report their state
    # @return [Light, LightCollection] self for chaining
    def refresh
      send_message(Protocol::Light::Get.new)
      self
    end
  end
end
