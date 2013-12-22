module LIFX
  module Protocol
    module AddressFields
      def AddressFields.included(mod)
        mod.instance_eval do
          hide :_reserved2
          hide :acknowledge # This isn't used yet

          string :target, length: 8
          string :site, length: 6
          bit1le :acknowledge
          bit15le :_reserved2
        end
      end
    end

    class Address < BinData::Record
      endian :little

      include AddressFields
    end
  end
end
