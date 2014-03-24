module LIFX
  # @api private
  class TagTable
    class Entry < Struct.new(:tag_id, :label, :site_id); end

    def initialize(entries: {})
      @entries = Hash.new { |h, k| h[k] = {} }
      entries.each do |k, v|
        @entries[k] = v
      end
    end

    def entries_with(tag_id: nil, site_id: nil, label: nil)
      entries.select do |entry|
        ret = []
        ret << (entry.tag_id == tag_id) if tag_id
        ret << (entry.site_id == site_id) if site_id
        ret << (entry.label == label) if label
        ret.all?
      end
    end

    def entry_with(**args)
      entries_with(**args).first
    end

    def update_table(tag_id:, label:, site_id:)
      entry = @entries[site_id][tag_id] ||= Entry.new(tag_id, label, site_id)
      entry.label = label
    end

    def delete_entries_with(tag_id: nil, site_id: nil, label: nil)
      matching_entries = entries_with(tag_id: tag_id, site_id: site_id, label: label)
      matching_entries.each do |entry|
        @entries[entry.site_id].delete(entry.tag_id)
      end
    end

    def tags
      entries.map(&:label).uniq
    end

    def entries
      @entries.values.map(&:values).flatten
    end
  end
end
