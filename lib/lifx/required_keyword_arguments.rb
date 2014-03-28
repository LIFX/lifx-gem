module LIFX
  module RequiredKeywordArguments
    def required!(name)
      backtrace = caller_locations(1).map { |c| c.to_s }
      ex = ArgumentError.new("Missing required keyword argument '#{name}'")
      ex.set_backtrace(backtrace)
      raise ex
    end
  end
end
