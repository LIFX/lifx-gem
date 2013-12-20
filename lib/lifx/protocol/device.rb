# Generated code ahoy!
module LIFX
  module Protocol
    module Device
      module Service
        UDP = 1
        TCP = 2
      end

      class SetSite < BinData::Record
        endian :little

        bytes :site, length: 6
      end

      class GetPanGateway < BinData::Record
        endian :little

      end

      class StatePanGateway < BinData::Record
        endian :little

        uint8 :service
        uint32 :port
      end

      class GetTime < BinData::Record
        endian :little

      end

      class SetTime < BinData::Record
        endian :little

        uint64 :time
      end

      class StateTime < BinData::Record
        endian :little

        uint64 :time
      end

      class GetResetSwitch < BinData::Record
        endian :little

      end

      class StateResetSwitch < BinData::Record
        endian :little

        uint8 :position
      end

      class GetDummyLoad < BinData::Record
        endian :little

      end

      class SetDummyLoad < BinData::Record
        endian :little

        bool :on
      end

      class StateDummyLoad < BinData::Record
        endian :little

        bool :on
      end

      class GetMeshInfo < BinData::Record
        endian :little

      end

      class StateMeshInfo < BinData::Record
        endian :little

        float :signal
        uint32 :tx
        uint32 :rx
        int16 :mcu_temperature
      end

      class GetMeshFirmware < BinData::Record
        endian :little

      end

      class StateMeshFirmware < BinData::Record
        endian :little

        uint64 :build
        uint64 :install
        uint32 :version
      end

      class GetWifiInfo < BinData::Record
        endian :little

      end

      class StateWifiInfo < BinData::Record
        endian :little

        float :signal
        uint32 :tx
        uint32 :rx
        int16 :mcu_temperature
      end

      class GetWifiFirmware < BinData::Record
        endian :little

      end

      class StateWifiFirmware < BinData::Record
        endian :little

        uint64 :build
        uint64 :install
        uint32 :version
      end

      class GetPower < BinData::Record
        endian :little

      end

      class SetPower < BinData::Record
        endian :little

        uint16 :level
      end

      class StatePower < BinData::Record
        endian :little

        uint16 :level
      end

      class GetLabel < BinData::Record
        endian :little

      end

      class SetLabel < BinData::Record
        endian :little

        string :label, length: 32, trim_padding: true
      end

      class StateLabel < BinData::Record
        endian :little

        string :label, length: 32, trim_padding: true
      end

      class GetTags < BinData::Record
        endian :little

      end

      class SetTags < BinData::Record
        endian :little

        uint64 :tags
      end

      class StateTags < BinData::Record
        endian :little

        uint64 :tags
      end

      class GetTagLabels < BinData::Record
        endian :little

        uint64 :tags
      end

      class SetTagLabels < BinData::Record
        endian :little

        uint64 :tags
        string :label, length: 32, trim_padding: true
      end

      class StateTagLabels < BinData::Record
        endian :little

        uint64 :tags
        string :label, length: 32, trim_padding: true
      end

      class GetVersion < BinData::Record
        endian :little

      end

      class StateVersion < BinData::Record
        endian :little

        uint32 :vendor
        uint32 :product
        uint32 :version
      end

      class GetInfo < BinData::Record
        endian :little

      end

      class StateInfo < BinData::Record
        endian :little

        uint64 :time
        uint64 :uptime
        uint64 :downtime
      end

      class GetMcuRailVoltage < BinData::Record
        endian :little

      end

      class StateMcuRailVoltage < BinData::Record
        endian :little

        uint32 :voltage
      end

      class Reboot < BinData::Record
        endian :little

      end

      class SetFactoryTestMode < BinData::Record
        endian :little

        bool :on
      end

      class DisableFactoryTestMode < BinData::Record
        endian :little

      end

      class StateFactoryTestMode < BinData::Record
        endian :little

        bool :on
        bool :disabled
      end

    end
  end
end
