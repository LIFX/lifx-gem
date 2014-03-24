module LIFX
  module Protocol
    # @api private
    module Wan
      class ConnectPlain < Payload
        endian :little

        string :user, length: 32, trim_padding: true
        string :pass, length: 32, trim_padding: true
      end

      class ConnectKey < Payload
        endian :little

        string :auth_key, length: 32
      end

      class StateConnect < Payload
        endian :little

        string :auth_key, length: 32
      end

      class Sub < Payload
        endian :little

        string :target, length: 8
        string :site, length: 6
        bool :device # 0 - Targets a device. 1 - Targets a tag.
      end

      class Unsub < Payload
        endian :little

        string :target, length: 8
        string :site, length: 6
        bool :device # 0 - Targets a device. 1 - Targets a tag.
      end

      class StateSub < Payload
        endian :little

        string :target, length: 8
        string :site, length: 6
        bool :device # 0 - Targets a device. 1 - Targets a tag.
      end

    end
  end
end
