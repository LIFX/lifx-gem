module LIFX
  module Observable
    def add_observer(obj, &callback)
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

    def observers
      @_observers ||= {}
    end
  end
end
