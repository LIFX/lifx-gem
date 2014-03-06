require 'lifx/routing_table'
require 'lifx/tag_table'

module LIFX
  class RoutingManager
    # RoutingManager manages a routing table of site <-> device
    # It can resolve a target to ProtocolPaths and manages the TagTable

    def initialize(context: )
      @context = context
      @routing_table = RoutingTable.new
      @tag_table = TagTable.new
    end

    def resolve_target(target)
      if target.tag?
        raise "can't handle this yet"
      elsif target.broadcast?
        if @routing_table.site_ids.empty?
          [ProtocolPath.new(site_id: "\x00".b * 6, tag_ids: [])]
        else
          @routing_table.site_ids.map { |site_id| ProtocolPath.new(site_id: site_id, tag_ids: []) }
        end
      elsif target.site_id
        [ProtocolPath.new(site_id: target.site_id, device_id: target.device_id)]
      else
        site_id = @routing_table.site_id_for_device_id(target.device_id)
        if site_id
          [ProtocolPath.new(site_id: site_id, device_id: target.device_id)]
        else
          @routing_table.site_ids.map { |site_id| ProtocolPath.new(site_id: site_id, device_id: target.device_id)}
        end
      end
    end

    def update_from_message(message)
      return if message.tagged?

      @routing_table.update_table(site_id: message.site_id, device_id: message.device_id)
      case message.payload
      when Protocol::Device::StateTagLabels
        @tag_table.update_from_message(message)
      end
    end
  end
end
