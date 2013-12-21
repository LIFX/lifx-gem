# Generated code ahoy!
module LIFX
  module Protocol
    module Wan
      class ConnectPlain < BinData::Record
        endian :little

        string :user, length: 32, trim_padding: true
        string :pass, length: 32, trim_padding: true
      end

      class ConnectKey < BinData::Record
        endian :little

        string :auth_key, length: 32
      end

      class StateConnect < BinData::Record
        endian :little

        string :auth_key, length: 32
      end

      class Sub < BinData::Record
        endian :little

        string :target, length: 8
        string :site, length: 6
        bool :device # 0 - Targets a device. 1 - Targets a tag.
      end

      class Unsub < BinData::Record
        endian :little

        string :target, length: 8
        string :site, length: 6
        bool :device # 0 - Targets a device. 1 - Targets a tag.
      end

      class StateSub < BinData::Record
        endian :little

        string :target, length: 8
        string :site, length: 6
        bool :device # 0 - Targets a device. 1 - Targets a tag.
      end

    end
  end
end
