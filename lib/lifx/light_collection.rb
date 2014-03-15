require 'lifx/light_target'

module LIFX
  # LightCollection represents a collection of {Light}s, which can either refer to
  # all lights on a {NetworkContext}, or lights
  class LightCollection
    include LightTarget
    include Enumerable
    extend Forwardable

    class TagNotFound < ArgumentError; end

    # Refers to {NetworkContext} the instance belongs to
    # @return [NetworkContext]
    attr_reader :context

    # Tag of the collection. `nil` represents all lights
    # @return [String]
    attr_reader :tag

    # Creates a {LightCollection} instance. Should not be used directly.
    # @api private
    # @param context: [NetworkContext] NetworkContext this collection belongs to
    # @param tag: [String] Tag 
    def initialize(context:, tag: nil)
      @context = context
      @tag = tag
      @lights = tag ? context.all_lights.select { |l| l.tags.include?(tag) } : context.all_lights
    end

    # Queues a {Protocol::Payload} to be sent to bulbs in the collection
    # @param payload [Protocol::Payload] Payload to be sent
    # @api private
    # @return [LightCollection] self for chaining
    def send_message(payload)
      if tag
        context.send_message(target: Target.new(tag: tag), payload: payload)
      else
        context.send_message(target: Target.new(broadcast: true), payload: payload)
      end
      self
    end

    # Returns a {Light} with device id matching `id`
    # @param id [String] Device ID
    # @return [Light]
    def with_id(id)
      @lights.find { |l| l.id == id}
    end

    # Returns a {Light} with its label matching `label`
    # @param label [String, Regexp] Label
    # @return [Light]
    def with_label(label)
      if label.is_a?(Regexp)
        @lights.find { |l| l.label =~ label }
      else
        @lights.find { |l| l.label == label }
      end
    end

    # Returns a {LightCollection} of {Light}s tagged with `tag`
    # @param tag [String] Tag
    # @return [LightCollection]
    def with_tag(tag)
      if context.tags.include?(tag)
        self.class.new(context: context, tag: tag)
      else
        raise TagNotFound.new("No such tag '#{tag}'")
      end
    end

    # Returns an Array of {Light}s
    # @return [Array<Light>]
    def lights
      @lights.dup
    end

    # Returns a nice string representation of itself
    # @return [String]
    def to_s
      %Q{#<#{self.class.name} lights=#{lights}#{tag ? " tag=#{tag}" : ''}>}
    end
    alias_method :inspect, :to_s

    def_delegators :lights, :empty?, :each
  end
end
