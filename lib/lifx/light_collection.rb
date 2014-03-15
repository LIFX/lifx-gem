require 'lifx/light_target'

module LIFX
  class LightCollection
    include LightTarget
    extend Forwardable

    class TagNotFound < ArgumentError; end
    # Represents a collection of lights
    attr_reader :tag, :context

    def initialize(context:, tag: nil, lights: context.all_lights)
      @context = context
      @tag = tag
      @lights = tag ? lights.select { |l| l.tags.include?(tag) } : lights
    end

    def send_message(payload)
      if tag
        context.send_message(target: Target.new(tag: tag), payload: payload)
      else
        context.send_message(target: Target.new(broadcast: true), payload: payload)
      end
      self
    end

    def with_id(id)
      @lights.find { |l| l.id == id}
    end

    def with_label(label)
      if label.is_a?(Regexp)
        @lights.find { |l| l.label =~ label }
      else
        @lights.find { |l| l.label == label }
      end
    end

    def with_tag(tag)
      if context.tags.include?(tag)
        self.class.new(context: context, tag: tag, lights: lights)
      else
        raise TagNotFound.new("No such tag '#{tag}'")
      end
    end

    def lights
      @lights
    end

    def to_s
      %Q{#<#{self.class.name} lights=#{lights}#{tag ? " tag=#{tag}" : ''}>}
    end
    alias_method :inspect, :to_s

    def_delegators :lights, :empty?, :length, :count, :to_a, :[], :find, :each, :first, :last, :map, :to_a
  end
end
