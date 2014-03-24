require 'lifx/utilities'

module LIFX
  # @private
  class ProtocolPath
    # ProtocolPath contains all the addressable information that is required
    # for the protocol.
    # It handles the conversion between raw binary and hex strings
    # as well as raw tags_field to tags array
    include Utilities

    attr_accessor :raw_site, :raw_target, :tagged

    def initialize(raw_site: "\x00".b * 6, raw_target: "\x00".b * 8, tagged: false,
                   site_id: nil, device_id: nil, tag_ids: nil)
      self.raw_site = raw_site
      self.raw_target = raw_target
      self.tagged = tagged

      self.site_id = site_id if site_id
      self.device_id = device_id if device_id
      self.tag_ids = tag_ids if tag_ids
    end

    def site_id
      raw_site.unpack('H*').join
    end

    def site_id=(value)
      self.raw_site = [value].pack('H12').b
    end

    def device_id
      if !tagged?
        raw_target[0...6].unpack('H*').join
      else
        nil
      end
    end

    def device_id=(value)
      self.raw_target = [value].pack('H16').b
      self.tagged = false
    end

    def tag_ids
      if tagged?
        tag_ids_from_field(tags_field)
      else
        nil
      end
    end

    def tag_ids=(values)
      self.tags_field = values.reduce(0) do |value, tag_id|
        value |= 2 ** tag_id
      end
    end

    def tagged?
      !!tagged
    end

    def all_sites?
      site_id == "000000000000"
    end

    def all_tags?
      tagged? && tag_ids.empty?
    end

    protected

    def tags_field
      raw_target.unpack('Q').first
    end

    def tags_field=(value)
      self.raw_target = [value].pack('Q').b
      self.tagged = true
    end


  end
end
