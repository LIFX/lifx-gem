require 'spec_helper'

module LIFX
  describe Client, integration: true do
    describe '#sync' do
      it 'schedules sending all messages to be executed at the same time' do
        if lights.count < 3
          pending "This test requires 3 or more lights tagged under Test"
          return
        end

        lifx.discover! do
          lights.count >= 3
        end

        white = LIFX::Color.white(brightness: 0.5)
        lights.set_color(white, duration: 0)
        sleep 1

        udp = Transport::UDP.new('0.0.0.0', 56750)
        msgs = []
        udp.add_observer(self) do |message:, ip:, transport:|
          msgs << message if message.payload.is_a?(Protocol::Light::SetWaveform)
        end
        udp.listen

        delay = lifx.sync do
          lights.each do |light|
            light.pulse(LIFX::Color.hsb(rand(360), 1, 1), period: 1)
          end
        end

        msgs.count.should == lights.count
        msgs.map(&:at_time).uniq.count.should == 1

        flush
      end
    end
  end
end
