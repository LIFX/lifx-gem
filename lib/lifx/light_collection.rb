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
    end

    def with_tag(tag_label)
      self.class.new(scope: scope, tags: [tag_label])
    end

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

    def_delegators :lights, :to_a, :[], :find, :each, :first, :last, :map
  end
end