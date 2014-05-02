require 'spec_helper'
require 'objspace'

RSpec::Matchers.define :have_instance_count_of do |expected|
  match do |actual|
    ObjectSpace.each_object(actual).select { |o| o.to_s rescue false }.count == expected
  end

  failure_message_for_should do |actual|
    "expected that #{actual} to have instance count of #{expected} but got #{ObjectSpace.each_object(actual).count}"
  end
end

module LIFX
  describe "garbage collection" do
    describe "transports" do
      it "cleans up the transports when a client is cleaned up" do
        client = Client.new(transport_manager: TransportManager::LAN.new)

        client.stop
        client = nil

        GC.start
        GC.start # Try to push stuff off the C stack

        ObjectSpace.each_object(Class).select { |klass| klass.to_s =~ /^LIFX/ }.each do |klass|
          next if klass == LIFX::Thread # Threads seem to stay around but do get GC'd
          expect(klass).to have_instance_count_of(0)
        end
      end
    end
  end
end
