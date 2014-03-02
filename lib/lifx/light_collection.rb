require 'lifx/light_target'

module LIFX
  class LightCollection
    include LightTarget
    extend Forwardable

    # Stores an array of lights and handles addressing multiple lights
    attr_reader :scope, :tags

    def initialize(scope: raise(ArgumentError, "scope required"), tags: [])
      if !scope.respond_to?(:sites)
        raise(ArgumentError, "scope must respond to sites")
      end
      @scope = scope
      @tags = tags
    end

    def queue_write(params)
      scope.sites.each do |site|
        tags_field = site.tag_manager.tags_field_for_tags(*tags)
        site.queue_write(params.merge(tagged: true, tags: tags_field))
      end
      self
    end

    def with_tags(*tag_labels)
      self.class.new(scope: scope, tags: tag_labels)
    end
    alias_method :with_tag, :with_tags

    def lights
      scope.sites.map do |site|
        tags_field = site.tag_manager.tags_field_for_tags(*tags)
        if tags_field.zero?
          site.lights
        else
          site.lights.select { |light| (light.tags_field & tags_field) > 0 }
        end
      end.flatten
    end

    def to_s
      %Q{#<#{self.class.name} lights=#{lights} tags=#{tags}>}
    end
    alias_method :inspect, :to_s

    def_delegators :lights, :length, :count, :to_a, :[], :find, :each, :first, :last, :map
  end
end