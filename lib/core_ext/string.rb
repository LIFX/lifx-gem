class String
  if !method_defined(:b)
    def b
      force_encoding(Encoding::BINARY)
    end
  end
end