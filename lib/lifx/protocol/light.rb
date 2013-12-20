module LIFX
  module Protocol
    module Light
      module Waveform
        SAW = 0
        SINE = 1
        HALF_SINE = 2
        TRIANGLE = 3
        PULSE = 4
      end

      class Hsbk < BinData::Record
        endian :little

        uint16 :hue
        uint16 :saturation
        uint16 :brightness
        uint16 :kelvin
      end

      class Get < BinData::Record
        endian :little

      end

      class Set < BinData::Record
        endian :little

        uint8 :stream
        hsbk :color
        uint32 :duration
      end

      class SetWaveform < BinData::Record
        endian :little

        uint8 :stream
        bool :transient
        hsbk :color
        uint32 :period
        float :cycles
        int16 :duty_cycle
        uint8 :waveform
      end

      class SetDimAbsolute < BinData::Record
        endian :little

        int16 :brightness
        uint32 :duration
      end

      class SetDimRelative < BinData::Record
        endian :little

        int32 :brightness
        uint32 :duration
      end

      class Rgbw < BinData::Record
        endian :little

        uint16 :red
        uint16 :green
        uint16 :blue
        uint16 :white
      end

      class SetRgbw < BinData::Record
        endian :little

        rgbw :color
      end

      class State < BinData::Record
        endian :little

        hsbk :color
        int16 :dim
        uint16 :power
        string :label, length: 32, trim_padding: true
        uint64 :tags
      end

      class GetRailVoltage < BinData::Record
        endian :little

      end

      class StateRailVoltage < BinData::Record
        endian :little

        uint32 :voltage
      end

      class GetTemperature < BinData::Record
        endian :little

      end

      class StateTemperature < BinData::Record
        endian :little

        int16 :temperature
      end

      class Xyz < BinData::Record
        endian :little

        float :x
        float :y
        float :z
      end

      class SetCalibrationCoefficients < BinData::Record
        endian :little

        xyz :r
        xyz :g
        xyz :b
        xyz :w
      end

    end
  end
end
