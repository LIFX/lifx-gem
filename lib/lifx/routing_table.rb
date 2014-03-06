module LIFX
  class RoutingTable
    class Entry < Struct.new(:site_id, :device_id, :tag_ids, :last_seen); end
    # RoutingTable stores the device <-> site mapping
    def initialize
      @device_site_mapping = {}
    end

    def update_table(site_id:, device_id:, tag_ids: nil)
      device_mapping = @device_site_mapping[device_id] ||= Entry.new(site_id, device_id, [])
      device_mapping.last_seen = Time.now
      device_mapping.tag_ids = tag_ids if tag_ids
    end

    def entry_for_device_id(device_id)
      @device_site_mapping[device_id]
    end

    def site_id_for_device_id(device_id)
      entry = entry_for_device_id(device)
      entry ? entry.site_id : nil
    end

    def site_ids
      @device_site_mapping.values.map(&:site_id).uniq
    end
  end
end
