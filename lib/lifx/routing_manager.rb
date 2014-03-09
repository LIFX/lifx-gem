require 'lifx/routing_table'
require 'lifx/tag_table'
require 'lifx/utilities'

module LIFX
  class RoutingManager
    include Utilities
    # RoutingManager manages a routing table of site <-> device
    # It can resolve a target to ProtocolPaths and manages the TagTable

    attr_reader :context, :tag_table, :routing_table

    def initialize(context:, cache_path: nil)
      @context = context

      initialize_cache(cache_path)
      @routing_table = RoutingTable.new(entries: cache.fetch('routing_table', {}))
      @tag_table = TagTable.new(entries: cache.fetch('tag_table', {}))
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
      return if message.tagged?

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
      else
        @routing_table.update_table(site_id: message.site_id, device_id: message.device_id)
      end
    end

    def refresh_site(site_id)
      context.send_message(target: Target.new(site_id: site_id), payload: Protocol::Device::GetTagLabels.new(tags: UINT64_MAX))
      context.send_message(target: Target.new(site_id: site_id), payload: Protocol::Device::GetTags.new)
    end

    protected

    def initialize_cache(cache_path)
      return unless cache_path
      if File.exists?(cache_path)
        begin
          @cache = read_cache(cache_path)
        rescue => ex
          logger.warn("Could not load cache at path: #{path} - #{ex}")
        end
      end
      at_exit do
        persist_cache(cache_path)
      end
    end

    def read_cache(cache_path)
      YAML.load(File.read(cache_path))
    end

    def persist_cache(cache_path)
      cache['routing_table'] = routing_table.entries
      cache['tag_table']     = tag_table.entries
      dir = File.dirname(cache_path)
      FileUtils.mkdir_p(dir) unless Dir.exists?(dir)
      File.open(cache_path, 'w') do |io|
        io.write(YAML.dump(cache))
      end
    end

    def cache
      @cache ||= {}
    end
  end
end
