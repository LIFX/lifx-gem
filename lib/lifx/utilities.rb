module LIFX
  module Utilities
    def try_until(condition_proc, timeout_exception: Timeout::Error, timeout: 3, retry_wait: 0.5, &action_block)
      Timeout.timeout(timeout) do
        while !condition_proc.call
          action_block.call
          sleep(retry_wait)
        end
      end
    rescue Timeout::Error
      raise timeout_exception
    end

    def tag_ids_from_field(tags_field)
      (0...64).to_a.select { |t| (tags_field & (2 ** t)) > 0 }
    end
  end
end
