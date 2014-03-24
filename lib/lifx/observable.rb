module LIFX
  # @private
  module Observable
    class ObserverCallbackMismatch < ArgumentError; end
    def add_observer(obj, &callback)
      if !callback_has_required_keys?(callback)
        raise ObserverCallbackMismatch.new
      end
      observers[obj] = callback
    end

    def remove_observer(obj)
      observers.delete(obj)
    end

    def notify_observers(**args)
      observers.each do |_, callback|
        callback.call(**args)
      end
    end

    def callback_has_required_keys?(callback)
      (required_keys_for_callback - required_keys_in_proc(callback)).empty?
    end

    def observer_callback_definition
      nil
    end

    def required_keys_for_callback
      @_required_keys_for_callback ||= begin
        return [] if !observer_callback_definition
        required_keys_in_proc(observer_callback_definition)
      end
    end

    def required_keys_in_proc(proc)
      proc.parameters.select do |type, _|
        type == :keyreq
      end.map(&:last)
    end

    def observers
      @_observers ||= {}
    end
  end
end
