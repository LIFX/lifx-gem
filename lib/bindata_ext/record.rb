require 'stringio'
BinData::Record
module BinData
  class Record
    def pack
      s = StringIO.new
      write(s)
      s.string.force_encoding(Encoding::BINARY)
    end
  end
end