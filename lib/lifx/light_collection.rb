require 'lifx/light_target'

module LIFX
  # LightCollection represents a collection of {Light}s, which can either refer to
  # all lights on a {NetworkContext}, or lights
  class LightCollection
    include LightTarget
    include Enumerable
    include RequiredKeywordArguments
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
    def initialize(context: required!(:context), tag: nil)
      @context = context
      @tag = tag
    end

    # Queues a {Protocol::Payload} to be sent to bulbs in the collection
    # @param payload [Protocol::Payload] Payload to be sent
    # @param acknowledge: [Boolean] whether recipients should acknowledge message
    # @param at_time: [Integer] Unix epoch in milliseconds to run the payload. Only applicable to certain payload types.
    # @api private
    # @return [LightCollection] self for chaining
    def send_message(payload, acknowledge: false, at_time: nil)
      if tag
        context.send_message(target: Target.new(tag: tag), payload: payload, acknowledge: acknowledge, at_time: at_time)
      else
        context.send_message(target: Target.new(broadcast: true), payload: payload, acknowledge: acknowledge, at_time: at_time)
      end
      self
    end

    # Returns a {Light} with device id matching `id`
    # @param id [String] Device ID
    # @return [Light]
    def with_id(id)
      lights.find { |l| l.id == id}
    end

    # Returns a {Light} with its label matching `label`
    # @param label [String, Regexp] Label
    # @return [Light]
    def with_label(label)
      if label.is_a?(Regexp)
        lights.find { |l| l.label(fetch: false) =~ label }
      else
        lights.find { |l| l.label(fetch: false) == label }
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
      if tag
        context.all_lights.select { |l| l.tags.include?(tag) }
      else
        context.all_lights
      end
    end

    DEFAULT_ALIVE_THRESHOLD = 30 # seconds
    # Returns an Array of {Light}s considered alive
    # @param threshold: The maximum number of seconds a {Light} was last seen to be considered alive
    # @return [Array<Light>] Lights considered alive
    def alive(threshold: DEFAULT_ALIVE_THRESHOLD)
      lights.select { |l| l.seconds_since_seen <= threshold }
    end

    # Returns an Array of {Light}s considered stale
    # @param threshold: The minimum number of seconds since a {Light} was last seen to be considered stale
    # @return [Array<Light>] Lights considered stale
    def stale(threshold: DEFAULT_ALIVE_THRESHOLD)
      lights.select { |l| l.seconds_since_seen > threshold }
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
