module LIFX
  class RoutingTable
    class Entry < Struct.new(:site_id, :device_id, :last_seen); end
    # RoutingTable stores the device <-> site mapping
    def initialize
      @device_site_mapping = {}
    end

    def update_from_message(message)
      return if message.tagged?
      @device_site_mapping[message.device_id] ||= Entry.new(message.site_id, message.device_id, Time.now)
      @device_site_mapping[message.device_id].last_seen = Time.now
    end

    def site_id_for_device_id(device_id)
      entry = @device_site_mapping[device_id]
      entry ? entry.site_id : nil
    end

    def site_ids
      @device_site_mapping.values.map(&:site_id)
    end
  end
end