module LIFX
  module Colors
    DEFAULT_KELVIN = 3500

    {
      red: 0,
      orange: 36,
      yellow: 60,
      green: 120,
      cyan: 195,
      blue: 250,
      purple: 280,
      pink: 325
    }.each do |color, hue|
      define_method(color) do |saturation: 1.0, brightness: 1.0, kelvin: DEFAULT_KELVIN|
        Color.new(hue, saturation, brightness, kelvin)
      end
    end

    # Helper to create a white {Color}
    # @param brightness: [Float] Valid range: `0..1`
    # @param kelvin: [Integer] Valid range: `2500..9000`
    # @return [Color]
    def white(brightness: 1.0, kelvin: DEFAULT_KELVIN)
      Color.new(0, 0, brightness, kelvin)
    end

    # Helper to create a random {Color}
    def random_color(hue: rand(360), saturation: rand, brightness: rand, kelvin: DEFAULT_KELVIN)
      Color.new(hue, saturation, brightness, kelvin)
    end
  end

  # LIFX::Color represents a color intervally by HSBK (Hue, Saturation, Brightness/Value, Kelvin).
  # It has methods to construct a LIFX::Color instance from various color representations.
  class Color < Struct.new(:hue, :saturation, :brightness, :kelvin)
    extend Colors
    UINT16_MAX = 65535
    KELVIN_MIN = 2500
    KELVIN_MAX = 9000

    class << self
      # Helper method to create from HSB/HSV
      # @param hue [Float] Valid range: `0..360`
      # @param saturation [Float] Valid range: `0..1`
      # @param brightness [Float] Valid range: `0..1`
      # @return [Color]
      def hsb(hue, saturation, brightness)
        new(hue, saturation, brightness, DEFAULT_KELVIN)
      end
      alias_method :hsv, :hsb

      # Helper method to create from HSBK/HSVK
      # @param hue [Float] Valid range: `0..360`
      # @param saturation [Float] Valid range: `0..1`
      # @param brightness [Float] Valid range: `0..1`
      # @param kelvin [Integer] Valid range: `2500..9000`
      # @return [Color]
      def hsbk(hue, saturation, brightness, kelvin)
        new(hue, saturation, brightness, kelvin)
      end

      # Helper method to create from HSL
      # @param hue [Float] Valid range: `0..360`
      # @param saturation [Float] Valid range: `0..1`
      # @param luminance [Float] Valid range: `0..1`
      # @return [Color]
      def hsl(hue, saturation, luminance)
        # From: http://ariya.blogspot.com.au/2008/07/converting-between-hsl-and-hsv.html
        l = luminance * 2
        saturation *= (l <= 1) ? l : 2 - l
        brightness = (l + saturation) / 2
        saturation = (2 * saturation) / (l + saturation)
        new(hue, saturation, brightness, DEFAULT_KELVIN)
      end

      # Helper method to create from RGB.
      # @note RGB is not the recommended way to create colors
      # @param r [Integer] Red. Valid range: `0..255`
      # @param g [Integer] Green. Valid range: `0..255`
      # @param b [Integer] Blue. Valid range: `0..255`
      # @return [Color]
      def rgb(r, g, b)
        r = r / 255.0
        g = g / 255.0
        b = b / 255.0

        max = [r, g, b].max
        min = [r, g, b].min

        h = s = v = max
        d = max - min
        s = max.zero? ? 0 : d / max

        if max == min
          h = 0
        else
          case max
          when r
            h = (g - b) / d + (g < b ? 6 : 0)
          when g
            h = (b - r) / d + 2
          when b
            h = (r - g) / d + 4
          end
          h = h * 60
        end

        new(h, s, v, DEFAULT_KELVIN)
      end

      # Creates an instance from a {Protocol::Light::Hsbk} struct
      # @api private
      # @param hsbk [Protocol::Light::Hsbk]
      # @return [Color]
      def from_struct(hsbk)
        new(
          (hsbk.hue.to_f / UINT16_MAX) * 360,
          (hsbk.saturation.to_f / UINT16_MAX),
          (hsbk.brightness.to_f / UINT16_MAX),
          hsbk.kelvin
        )
      end
    end

    def initialize(hue, saturation, brightness, kelvin)
      hue = hue % 360
      super(hue, saturation, brightness, kelvin)
    end

    # Returns a new Color with the hue changed while keeping other attributes
    # @param hue [Float] Hue in degrees. `0..360`
    # @return [Color]
    def with_hue(hue)
      Color.new(hue, saturation, brightness, kelvin)
    end

    # Returns a new Color with the saturaiton changed while keeping other attributes
    # @param saturaiton [Float] Saturation as float. `0..1`
    # @return [Color]
    def with_saturation(saturation)
      Color.new(hue, saturation, brightness, kelvin)
    end

    # Returns a new Color with the brightness changed while keeping other attributes
    # @param brightness [Float] Brightness as float. `0..1`
    # @return [Color]
    def with_brightness(brightness)
      Color.new(hue, saturation, brightness, kelvin)
    end

    # Returns a new Color with the kelvin changed while keeping other attributes
    # @param kelvin [Integer] Kelvin. `2500..9000`
    # @return [Color]
    def with_kelvin(kelvin)
      Color.new(hue, saturation, brightness, kelvin)
    end

    # Returns a struct for use by the protocol
    # @api private
    # @return [Protocol::Light::Hsbk]
    def to_hsbk
      Protocol::Light::Hsbk.new(
        hue: (hue / 360.0 * UINT16_MAX).to_i,
        saturation: (saturation * UINT16_MAX).to_i,
        brightness: (brightness * UINT16_MAX).to_i,
        kelvin: [KELVIN_MIN, kelvin.to_i, KELVIN_MAX].sort[1]
      )
    end

    # Returns hue, saturation, brightness and kelvin in an array
    # @return [Array<Float, Float, Float, Integer>]
    def to_a
      [hue, saturation, brightness, kelvin]
    end

    DEFAULT_SIMILAR_THRESHOLD = 0.001 # 0.1% variance
    # Checks if colours are equal to 0.1% variance
    # @param other [Color] Color to compare to
    # @param threshold: [Float] 0..1. Threshold to consider it similar
    # @return [Boolean]
    def similar_to?(other, threshold: DEFAULT_SIMILAR_THRESHOLD)
      return false unless other.is_a?(Color)
      conditions = []

      conditions << (((hue - other.hue).abs < (threshold * 360)) || begin
        # FIXME: Surely there's a better way.
        hues = [hue, other.hue].sort
        hues[0] += 360
        (hues[0] - hues[1]).abs < (threshold * 360)
      end)
      conditions << ((saturation - other.saturation).abs < threshold)
      conditions << ((brightness - other.brightness).abs < threshold)
      conditions.all?
    end
  end
end
