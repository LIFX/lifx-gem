module LIFX
  # LightTarget is a module that contains Light commands that can work
  # with either a single {Light} or multiple Lights via a {LightCollection}
  module LightTarget
    MSEC_PER_SEC   = 1000

    # Attempts to set the color of the light(s) to `color` asynchronously.
    # This method cannot guarantee that the message was received.
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

    # Attempts to apply a waveform to the light(s) asynchronously.
    # @note Don't use this directly.
    # @api private
    def set_waveform(color, waveform:,
                            cycles:,
                            stream: 0,
                            transient: true,
                            period: 1.0,
                            duty_cycle: 0.5,
                            acknowledge: false)
      send_message(Protocol::Light::SetWaveform.new(
        color: color.to_hsbk,
        waveform: waveform,
        cycles: cycles,
        stream: stream,
        transient: transient,
        period: (period * 1_000).to_i,
        duty_cycle: (duty_cycle * 65535).round - 32768
      ), acknowledge: acknowledge)
    end

    # Attempts to make the light(s) pulse `color` and then back to its original color. Asynchronous.
    # @param color [Color] Color to pulse
    # @param duty_cycle: [Float] Percentage of a cycle the light(s) is set to `color`
    # @param cycles: [Integer] Number of cycles
    # @param transient: [Boolean] If false, the light will remain at the color the waveform is at when it ends
    # @param period: [Integer] Number of seconds a cycle. Must be above 1.0 (?)
    # @param stream: [Integer] Unused
    def pulse(color, cycles: 1,
                     duty_cycle: 0.5,
                     transient: true,
                     period: 1.0,
                     stream: 0)
      set_waveform(color, waveform: Protocol::Light::Waveform::PULSE,
                          cycles: cycles,
                          duty_cycle: duty_cycle,
                          stream: stream,
                          transient: transient,
                          period: period)
    end

    # Attempts to make the light(s) transition to `color` and back in a smooth sine wave. Asynchronous.
    # @param color [Color] Color
    # @param cycles: [Integer] Number of cycles
    # @param transient: [Boolean] If false, the light will remain at the color the waveform is at when it ends
    # @param period: [Integer] Number of seconds a cycle. Must be above 1.0 (?)
    # @param stream: [Integer] Unused
    def sine(color, cycles: 1,
                    period: 1.0,
                    transient: true,
                    stream: 0)
      set_waveform(color, waveform: Protocol::Light::Waveform::SINE,
                          cycles: cycles,
                          duty_cycle: 0,
                          stream: stream,
                          transient: transient,
                          period: period)
    end

    # Attempts to make the light(s) transition to `color` smoothly, then immediately back to its original color. Asynchronous.
    # @param color [Color] Color
    # @param cycles: [Integer] Number of cycles
    # @param transient: [Boolean] If false, the light will remain at the color the waveform is at when it ends
    # @param period: [Integer] Number of seconds a cycle. Must be above 1.0 (?)
    # @param stream: [Integer] Unused
    def half_sine(color, cycles: 1,
                         period: 1.0,
                         transient: true,
                         stream: 0)
      set_waveform(color, waveform: Protocol::Light::Waveform::HALF_SINE,
                          cycles: cycles,
                          stream: stream,
                          transient: transient,
                          period: period)
    end

    # Attempts to make the light(s) transition to `color` linearly and back. Asynchronous.
    # @param color [Color] Color to pulse
    # @param cycles: [Integer] Number of cycles
    # @param transient: [Boolean] If false, the light will remain at the color the waveform is at when it ends
    # @param period: [Integer] Number of seconds a cycle. Must be above 1.0 (?)
    # @param stream: [Integer] Unused
    def triangle(color, cycles: 1,
                     period: 1.0,
                     transient: true,
                     stream: 0)
      set_waveform(color, waveform: Protocol::Light::Waveform::TRIANGLE,
                          cycles: cycles,
                          stream: stream,
                          transient: transient,
                          period: period)
    end

    # Attempts to make the light(s) transition to `color` linearly, then instantly back. Asynchronous.
    # @param color [Color] Color to saw wave
    # @param cycles: [Integer] Number of cycles
    # @param transient: [Boolean] If false, the light will remain at the color the waveform is at when it ends
    # @param period: [Integer] Number of seconds a cycle. Must be above 1.0 (?)
    # @param stream: [Integer] Unused
    def saw(color, cycles: 1,
                   period: 1.0,
                   transient: true,
                   stream: 0)
      set_waveform(color, waveform: Protocol::Light::Waveform::SAW,
                          cycles: cycles,
                          stream: stream,
                          transient: transient,
                          period: period)
    end

    # Attempts to set the power state to `value` asynchronously.
    # This method cannot guarantee the message was received.
    # @param value [0, 1] 0 for off, 1 for on
    # @return [Light, LightCollection] self for chaining
    def set_power(value)
      send_message(Protocol::Device::SetPower.new(level: value))
      self
    end

    # Attempts to turn the light(s) on asynchronously.
    # This method cannot guarantee the message was received.
    # @return [Light, LightCollection] self for chaining
    def turn_on
      set_power(1)
    end

    # Attempts to turn the light(s) off asynchronously.
    # This method cannot guarantee the message was received.
    # @return [Light, LightCollection] self for chaining
    def turn_off
      set_power(0)
    end

    # Requests light(s) to report their state
    # This method cannot guarantee the message was received.
    # @return [Light, LightCollection] self for chaining
    def refresh
      send_message(Protocol::Light::Get.new)
      self
    end

    # Attempts to set the site id of the light.
    # Will clear label and tags. This method cannot guarantee message receipt.
    # @note Don't use this unless you know what you're doing.
    # @api private
    # @param site_id [String] Site ID
    # @return [void]
    def set_site_id(site_id)
      send_message(Protocol::Device::SetSite.new(site: [site_id].pack('H*')))
    end

    NSEC_IN_SEC = 1_000_000_000
    # Attempts to set the device time on the targets
    # @api private
    # @param time [Time] The time to set
    # @return [void]
    def set_time(time = Time.now)
      send_message(Protocol::Device::SetTime.new(time: (time.to_f * NSEC_IN_SEC).round))
    end


    # Attempts to reboots the light(s).
    # This method cannot guarantee the message was received.
    # @return [Light, LightCollection] self for chaining
    def reboot!
      send_message(Protocol::Device::Reboot.new)
    end
  end
end
