module LIFX
  module Protocol
    module AddressFields
      def AddressFields.included(mod)
        mod.instance_eval do
          string :target, length: 8 # Look into refactoring using Choices
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
