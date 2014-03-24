module LIFX
  module Protocol
    # @api private
    module Device
      module Service
        UDP = 1
        TCP = 2
      end

      class SetSite < Payload
        endian :little

        string :site, length: 6
      end

      class GetPanGateway < Payload
        endian :little

      end

      class StatePanGateway < Payload
        endian :little

        uint8 :service
        uint32 :port
      end

      class GetTime < Payload
        endian :little

      end

      class SetTime < Payload
        endian :little

        uint64 :time # Nanoseconds since epoch.
      end

      class StateTime < Payload
        endian :little

        uint64 :time # Nanoseconds since epoch.
      end

      class GetResetSwitch < Payload
        endian :little

      end

      class StateResetSwitch < Payload
        endian :little

        uint8 :position
      end

      class GetMeshInfo < Payload
        endian :little

      end

      class StateMeshInfo < Payload
        endian :little

        float :signal # Milliwatts.
        uint32 :tx # Bytes.
        uint32 :rx # Bytes.
        int16 :mcu_temperature # Deci-celsius. 25.45 celsius is 2545
      end

      class GetMeshFirmware < Payload
        endian :little

      end

      class StateMeshFirmware < Payload
        endian :little

        uint64 :build # Firmware build nanoseconds since epoch.
        uint64 :install # Firmware install nanoseconds since epoch.
        uint32 :version # Firmware human readable version.
      end

      class GetWifiInfo < Payload
        endian :little

      end

      class StateWifiInfo < Payload
        endian :little

        float :signal # Milliwatts.
        uint32 :tx # Bytes.
        uint32 :rx # Bytes.
        int16 :mcu_temperature # Deci-celsius. 25.45 celsius is 2545
      end

      class GetWifiFirmware < Payload
        endian :little

      end

      class StateWifiFirmware < Payload
        endian :little

        uint64 :build # Firmware build nanoseconds since epoch.
        uint64 :install # Firmware install nanoseconds since epoch.
        uint32 :version # Firmware human readable version.
      end

      class GetPower < Payload
        endian :little

      end

      class SetPower < Payload
        endian :little

        uint16 :level # 0 Standby. > 0 On.
      end

      class StatePower < Payload
        endian :little

        uint16 :level # 0 Standby. > 0 On.
      end

      class GetLabel < Payload
        endian :little

      end

      class SetLabel < Payload
        endian :little

        string :label, length: 32, trim_padding: true
      end

      class StateLabel < Payload
        endian :little

        string :label, length: 32, trim_padding: true
      end

      class GetTags < Payload
        endian :little

      end

      class SetTags < Payload
        endian :little

        uint64 :tags
      end

      class StateTags < Payload
        endian :little

        uint64 :tags
      end

      class GetTagLabels < Payload
        endian :little

        uint64 :tags
      end

      class SetTagLabels < Payload
        endian :little

        uint64 :tags
        string :label, length: 32, trim_padding: true
      end

      class StateTagLabels < Payload
        endian :little

        uint64 :tags
        string :label, length: 32, trim_padding: true
      end

      class GetVersion < Payload
        endian :little

      end

      class StateVersion < Payload
        endian :little

        uint32 :vendor
        uint32 :product
        uint32 :version
      end

      class GetInfo < Payload
        endian :little

      end

      class StateInfo < Payload
        endian :little

        uint64 :time # Nanoseconds since epoch.
        uint64 :uptime # Nanoseconds since boot.
        uint64 :downtime # Nanoseconds off last power cycle.
      end

      class GetMcuRailVoltage < Payload
        endian :little

      end

      class StateMcuRailVoltage < Payload
        endian :little

        uint32 :voltage
      end

      class Reboot < Payload
        endian :little

      end

    end
  end
end
