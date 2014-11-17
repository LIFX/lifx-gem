module LIFX
  # @private
  module Observable
    class ObserverCallbackMismatch < ArgumentError; end
    class ObserverCallbackNotFound < ArgumentError; end

    def add_observer(obj, type, &callback)
      if !callback_type_exists?(type)
        raise ObserverCallbackNotFound.new("Callback #{type} not found in #{observer_callback_definition.keys}")
      end
      if !callback_has_required_keys?(type, callback)
        raise ObserverCallbackMismatch.new
      end
      observers[type][obj] = callback
    end

    def remove_observer(obj, type)
      observers[type].delete(obj)
    end

    def remove_observers
      observers.clear
    end

    def notify_observers(type, **args)
      if !callback_type_exists?(type)
        raise ObserverCallbackNotFound.new("Callback #{type} not found in #{observer_callback_definition.keys}")
      end
      observers[type].each do |_, callback|
        callback.call(**args)
      end
    end

    def callback_type_exists?(type)
      !!observer_callback_definition[type]
    end

    def callback_has_required_keys?(type, callback)
      (required_keys_for_callback(type) - required_keys_in_proc(callback)).empty?
    end

    def observer_callback_definition
      {}
    end

    def required_keys_for_callback(type)
      @_required_keys_for_callback ||= {}
      @_required_keys_for_callback[type] ||= begin
        return [] if !observer_callback_definition[type]
        required_keys_in_proc(observer_callback_definition[type])
      end
    end

    def required_keys_in_proc(proc)
      proc.parameters.select do |type, _|
        type == :keyreq
      end.map(&:last)
    end

    def observers
      @_observers ||= Hash.new { |h, k| h[k] = {} }
    end
  end
end
