module LIFX
  module Protocol
    module AddressFields
      def AddressFields.included(mod)
        mod.instance_eval do
          hide :_reserved2
          string :raw_target, length: 8
          string :raw_site, length: 6
          bool_bit1 :acknowledge
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
