require 'stringio'
BinData::Record
module BinData
  class Record
    def pack
      s = StringIO.new
      write(s)
      s.string.b
    end
  end
end