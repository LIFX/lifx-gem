require 'lifx/utilities'

module LIFX
  class TagTable
    class Entry < Struct.new(:id, :label, :site_id); end
    include Utilities

    def initialize
      # @entries is by label, then tag_id
      @entries = Hash.new { |h, k| h[k] = {} }
    end

    def entries_for_tag_label(label)
      @entries[label].values.flatten
    end

    def update_from_message(message)
      payload = message.payload
      return unless payload.is_a?(Protocol::Device::StateTagLabels)
      tag_ids = tag_ids_from_field(payload.tags)
      if payload.label.empty?
        # Null label means all the tag_ids in this payload are not used
        tags_to_delete = []
        @entries.each do |label, tag_id_entries|
          tag_ids.each do |id|
            tag_id_entries.delete(id)
          end
          if tag_id_entries.empty?
            tags_to_delete << label
          end
        end

        tags_to_delete.each do |tag|
          @entries.delete(tag)
        end
      else
        update_table(id: tag_ids.first, label: payload.label, site_id: message.site_id)
      end
    end

    def update_table(id:, label:, site_id:)
      @entries[label][tag_id] ||= Entry.new(id, label, site_id)
    end
  end
end
