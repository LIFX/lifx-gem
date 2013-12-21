require 'lifx/protocol/header'
require 'lifx/protocol/address'
require 'lifx/protocol/metadata'

module LIFX
  module Protocol
    class Message < BinData::Record
      endian :little
      
      include HeaderFields
      include AddressFields
      include MetadataFields

      rest :payload
    end
  end
end
