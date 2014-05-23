require 'weakref'

module LIFX
  # @api private
  # @private
  class TagManager
    # TagManager handles discovery of tags, resolving tags to [site_id, tags_field] pairs,
    # creating, setting and removing tags.

    # Stores site <-> [tag_name, tag_id]
    include Utilities
    include Logging
    include RequiredKeywordArguments

    attr_reader :context

    class TagLimitReached < StandardError; end

    def initialize(context: required!(:context), tag_table: required!(:tag_table))
      @context = WeakRef.new(context)
      @tag_table = tag_table
    end

    def create_tag(label: required!(:label), site_id: required!(:site_id))
      id = next_unused_id_on_site_id(site_id)
      raise TagLimitReached if id.nil?
      # Add the entry for the tag we're about to create to prevent a case where
      # we don't receive a StateTagLabels before another tag gets created
      @tag_table.update_table(tag_id: id, label: label, site_id: site_id)
      context.send_message(target: Target.new(site_id: site_id),
                           payload: Protocol::Device::SetTagLabels.new(tags: id_to_tags_field(id), label: label.encode('utf-8')))
    end

    def add_tag_to_device(tag: required!(:tag), device: required!(:device))
      tag_entry = entry_with(label: tag, site_id: device.site_id)
      if !tag_entry
        create_tag(label: tag, site_id: device.site_id)
        tag_entry = entry_with(label: tag, site_id: device.site_id)
      end

      device_tags_field = device.tags_field
      device_tags_field |= id_to_tags_field(tag_entry.tag_id)
      device.send_message!(Protocol::Device::SetTags.new(tags: device_tags_field), wait_for: Protocol::Device::StateTags) do
        device.tags.include?(tag)
      end
    end

    def remove_tag_from_device(tag: required!(:tag), device: required!(:device))
      tag_entry = entry_with(label: tag, site_id: device.site_id)
      return if !tag_entry

      device_tags_field = device.tags_field
      device_tags_field &= ~id_to_tags_field(tag_entry.tag_id)
      device.send_message!(Protocol::Device::SetTags.new(tags: device_tags_field), wait_for: Protocol::Device::StateTags) do
        !device.tags.include?(tag)
      end
    end

    def tags
      @tag_table.tags
    end

    def unused_tags
      @tag_table.tags.select do |tag|
        context.lights.with_tag(tag).empty?
      end
    end

    # This will clear out tags that currently do not resolve to any devices.
    # If used when devices that are tagged with a tag that is not attached to an
    # active device, it will effectively untag them when they're back on.
    def purge_unused_tags!
      unused_tags.each do |tag|
        logger.info("Purging tag '#{tag}'")
        entries_with(label: tag).each do |entry|
          payload = Protocol::Device::SetTagLabels.new(tags: id_to_tags_field(entry.tag_id), label: '')
          context.send_message(target: Target.new(site_id: entry.site_id),
                               payload: payload,
                               acknowledge: true)
        end
      end
      Timeout.timeout(5) do
        while !unused_tags.empty?
          sleep 0.1
        end
      end
    end

    protected

    VALID_TAG_IDS = (0...64).to_a.freeze

    def entry_with(**args)
      entries_with(**args).first
    end

    def entries_with(**args)
      @tag_table.entries_with(**args)
    end

    def id_to_tags_field(id)
      2 ** id
    end

    def next_unused_id_on_site_id(site_id)
      (VALID_TAG_IDS - entries_with(site_id: site_id).map(&:tag_id)).first
    end
  end
end
