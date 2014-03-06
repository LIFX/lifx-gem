module LIFX
  module Utilities
    def wait_until(seconds: 10, spin_wait: 0.1, &block)
      Timeout.timeout(seconds) do
        while !(ret = block.call) do
          sleep(spin_wait)
        end
        return ret
      end
    rescue Timeout::Error

    end

    def tag_ids_from_field(uint64)
      (0...64).to_a.select { |t| (tags_field & (2 ** t)) > 0 }
    end
  end
end
