module BinData
  class Bool < Primitive
    uint8 :_value

    def get
      (self._value || 0) > 0
    end

    def set(value)
      self._value = value ? 1 : 0
    end
  end

  class BoolBit1 < Primitive
    bit1le :_value

    def get
      (self._value || 0) > 0
    end

    def set(value)
      self._value = value ? 1 : 0
    end
  end
end
