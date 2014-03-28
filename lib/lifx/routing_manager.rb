require 'lifx/routing_table'
require 'lifx/tag_table'
require 'lifx/utilities'

module LIFX
  # @private
  class RoutingManager
    include Utilities
    include RequiredKeywordArguments

    # RoutingManager manages a routing table of site <-> device
    # It can resolve a target to ProtocolPaths and manages the TagTable

    attr_reader :context, :tag_table, :routing_table

    def initialize(context: required!(:context))
      @context = context
      @routing_table = RoutingTable.new
      @tag_table = TagTable.new
      @last_refresh_seen = {}
    end

    def resolve_target(target)
      if target.tag?
        @tag_table.entries_with(label: target.tag).map do |entry|
          ProtocolPath.new(site_id: entry.site_id, tag_ids: [entry.tag_id])
        end
      elsif target.broadcast?
        if @routing_table.site_ids.empty?
          [ProtocolPath.new(site_id: "\x00".b * 6, tag_ids: [])]
        else
          @routing_table.site_ids.map { |site_id| ProtocolPath.new(site_id: site_id, tag_ids: []) }
        end
      elsif target.site_id && target.device_id.nil?
        [ProtocolPath.new(site_id: target.site_id, tag_ids: [])]
      elsif target.site_id && target.device_id
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

    def tags_for_device_id(device_id)
      entry = @routing_table.entry_for_device_id(device_id)
      entry.tag_ids.map do |tag_id|
        tag = @tag_table.entry_with(site_id: entry.site_id, tag_id: tag_id)
        tag && tag.label
      end.compact
    end

    def update_from_message(message)
      if message.tagged?
        case message.payload
        when Protocol::Light::Get
          if message.path.all_tags?
            @last_refresh_seen[message.site_id] = Time.now
          end
        end
        return
      end

      payload = message.payload

      if !@routing_table.site_ids.include?(message.site_id)
        # New site detected, fire refresh events
        refresh_site(message.site_id)
      end
      case payload
      when Protocol::Device::StateTagLabels
        tag_ids = tag_ids_from_field(payload.tags)
        if payload.label.empty?
          tag_ids.each do |tag_id|
            @tag_table.delete_entries_with(site_id: message.site_id, tag_id: tag_id)
          end
        else
          @tag_table.update_table(site_id: message.site_id, tag_id: tag_ids.first, label: payload.label.to_s)
        end
      when Protocol::Device::StateTags, Protocol::Light::State
        @routing_table.update_table(site_id: message.site_id,
                                    device_id: message.device_id,
                                    tag_ids: tag_ids_from_field(message.payload.tags))
      end
      @routing_table.update_table(site_id: message.site_id, device_id: message.device_id)
    end

    MINIMUM_REFRESH_INTERVAL = 20
    def refresh
      @routing_table.site_ids.each do |site_id|
        next if (seen = @last_refresh_seen[site_id]) && Time.now - seen < MINIMUM_REFRESH_INTERVAL
        refresh_site(site_id)
      end
    end

    def refresh_site(site_id)
      get_lights(site_id)
      get_tag_labels(site_id)
    end

    def get_lights(site_id)
      context.send_message(target: Target.new(site_id: site_id), payload: Protocol::Light::Get.new)
    end

    UINT64_MAX = 2 ** 64 - 1
    def get_tag_labels(site_id)
      context.send_message(target: Target.new(site_id: site_id), payload: Protocol::Device::GetTagLabels.new(tags: UINT64_MAX))
    end
  end
end
