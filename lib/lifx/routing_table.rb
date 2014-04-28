module LIFX
  # @private
  class RoutingTable
    class Entry < Struct.new(:site_id, :device_id, :tag_ids, :last_seen); end
    # RoutingTable stores the device <-> site mapping
    def initialize(entries: {})
      @device_site_mapping = entries
    end

    def update_table(site_id: site_id, device_id: device_id, tag_ids: nil, last_seen: Time.now)
      device_mapping = @device_site_mapping[device_id] ||= Entry.new(site_id, device_id, [])
      device_mapping.site_id = site_id
      device_mapping.last_seen = last_seen
      device_mapping.tag_ids = tag_ids if tag_ids
    end

    def entry_for_device_id(device_id)
      @device_site_mapping[device_id]
    end

    def site_id_for_device_id(device_id)
      entry = entry_for_device_id(device_id)
      entry ? entry.site_id : nil
    end

    def site_ids
      entries.map(&:site_id).uniq
    end

    def entries
      @device_site_mapping.values
    end

    def clear_stale_entries(threshold: 60 * 5)
      @device_site_mapping.reject! do |device_id, entry|
        entry.last_seen < Time.now - threshold
      end
    end
  end
end
