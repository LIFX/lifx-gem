require 'thread'

module LIFX
  class Thread < ::Thread
    def abort
      if alive?
        kill.join
      end
    end
  end
end
