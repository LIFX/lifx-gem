require 'lifx/tag'

module LIFX
  class TagManager
    # Handles fetching tag labels
    # Keeping tag label states
    attr_reader :tags, :site

    class TagLimitReached < StandardError; end

    def initialize(site)
      @site = site
      @tags = {}
    end

    def discover
      site.queue_write(payload: Protocol::Device::GetTagLabels.new(tags: UINT64_MAX))
    end

    def on_message(message, ip, transport)
      payload = message.payload
      case payload
      when Protocol::Device::StateTagLabels
        add_or_update_tag(payload.tags, payload.label)
      end
    end

    def create_tag(tag_label)
      id = next_unused_id
      raise TagLimitReached if id.nil?
      site.queue_write(tagged: true, payload: Protocol::Device::SetTagLabels.new(tags: id_to_tags_field(id), label: tag_label))
      wait_until { tag } or raise "Couldn't create tag"
    end

    def add_tag_to_light(tag_label, light)
      tag = tag_with_label(tag_label)
      if !tag
        tag = create_tag(tag_label)
      end
      light_tags_field = light.tags_field
      light_tags_field |= id_to_tags_field(tag.id)
      light.queue_write(payload: Protocol::Device::SetTags.new(tags: light_tags_field))
    end

    def remove_tag_from_light(tag_label, light)
      tag = tag_with_label(tag_label)
      light_tags_field = light.tags_field
      light_tags_field &= ~id_to_tags_field(tag.id)
      light.queue_write(payload: Protocol::Device::SetTags.new(tags: light_tags_field))      
    end

    def tags_on_light(light)
      tags_field_to_ids(light.tags_field).map { |id| @tags[id].label }
    end

    protected

    VALID_TAG_IDS = (0...64).to_a.freeze

    def tag_with_label(label)
      @tags.values.find { |t| t.label == label }
    end

    def add_or_update_tag(tags_field, label)
      id = tags_field_to_id(tags_field)
      @tags[id] ||= Tag.new(site, id, label)
    end

    def tags_field_to_ids(tags_field)
      VALID_TAG_IDS.select do |i|
        tags_field & (2 ** i) > 0
      end
    end

    def tags_field_to_id(tags_field)
      tags_field_to_ids(tags_field).first
    end

    def id_to_tags_field(id)
      2 ** id
    end

    def next_unused_id
      (VALID_TAG_IDS - @tags.keys).first
    end
  end
end
