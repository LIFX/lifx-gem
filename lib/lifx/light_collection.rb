require 'lifx/light_target'

module LIFX
  class LightCollection
    include LightTarget
    extend Forwardable

    # Represents a collection of lights
    attr_reader :tag, :context

    def initialize(context:, tag: nil, lights: context.lights)
      @context = context
      @tag = tag
      @lights = lights
    end

    def send_message(payload)
      if tag
        context.send_message(target: Target.new(tag), payload: payload)
      else
        context.send_message(target: Target.new(broadcast: true), payload: payload)
      end
      self
    end

    def with_id(id)
      lights.find { |l| l.id == id}
    end

    def with_label(label)
      lights.find { |l| l.label == label }
    end

    def with_tag(*tag_labels)
      self.class.new(scope: scope, tags: tag_labels)
    end

    def lights
      if !tag
        lights
      else
        lights.select do |light|
          light.tags.include?(tag)
        end
      end
    end

    def to_s
      %Q{#<#{self.class.name} lights=#{lights} tags=#{tags}>}
    end
    alias_method :inspect, :to_s

    # def_delegators :lights, :length, :count, :to_a, :[], :find, :each, :first, :last, :map
  end
end
