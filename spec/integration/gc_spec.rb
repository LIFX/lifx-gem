require 'spec_helper'


RSpec::Matchers.define :have_instance_count_of do |expected|
  match do |actual|
    ObjectSpace.each_object(actual).count == expected
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

        expect(Transport::UDP).to have_instance_count_of(2)

        client = nil
        GC.start

        [Client, NetworkContext, TransportManager::Base, Transport::Base, Light, LightCollection].each do |klass|
          expect(klass).to have_instance_count_of(0)
        end
      end
    end
  end
end
