module LIFX
  # @private
  module Utilities
    def try_until(condition_proc, timeout_exception: TimeoutError,
                                            timeout: 3,
                                 condition_interval: 0.1,
                                    action_interval: 0.5,
                                             signal: nil, &action_block)
      Timeout.timeout(timeout) do
        m = Mutex.new
        time = 0
        while !condition_proc.call
          if Time.now.to_f - time > action_interval
            time = Time.now.to_f
            action_block.call
          end
          if signal
            m.synchronize do
              signal.wait(m, condition_interval)
            end
          else
            sleep(condition_interval)
          end
        end
      end
    rescue Timeout::Error
      raise timeout_exception if timeout_exception
    end

    def tag_ids_from_field(tags_field)
      (0...64).to_a.select { |t| (tags_field & (2 ** t)) > 0 }
    end
  end
end
