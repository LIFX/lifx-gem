require 'time'

module LIFX
  # LIFX::Firmware handles decoding firmware payloads
  # @private
  class Firmware < Struct.new(:build_time, :major, :minor)
    include Comparable

    def initialize(payload)
      self.build_time = decode_time(payload.build)
      self.major  = (payload.version >> 0x10)
      self.minor  = (payload.version &  0xFF)
    end

    def to_s
      "#<Firmware version=#{self.major}.#{self.minor}>"
    end
    alias_method :inspect, :to_s

    def <=>(obj)
      case obj
      when String
        major, minor = obj.split('.', 2).map(&:to_i)
        [self.major, self.minor] <=> [major, minor]
      when Firmware
        [self.major, self.minor] <=> [obj.major, obj.minor]
      else
        nil
      end
    end


    protected

    def decode_time(int)
      if int < 1300000000000000000
        year   = byte(int, 56) + 2000
        month  = bytes(int, 48, 40, 32).map(&:chr).join
        day    = byte(int, 24)
        hour   = byte(int, 16)
        min    = byte(int,  8)
        sec    = byte(int,  0)
        # Don't want to pull in DateTime just for DateTime.new
        Time.parse("%s %d %04d, %02d:%02d:%02d" % [month, day, year, hour, min, sec])
      else
        Time.at(int / 1000000000)
      end
    end

    def byte(n, pos)
      0xFF & (n >> pos)
    end

    def bytes(n, *range)
      range.map {|r| byte(n, r)}
    end
  end
end
