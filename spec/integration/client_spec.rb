require 'spec_helper'

module LIFX
  describe Client, integration: true do
    describe '#sync' do
      let(:minimum_lights) { 3 }
      let(:udp) { Transport::UDP.new('0.0.0.0', 56_750) }
      let(:white) { Color.white(brightness: 0.5) }

      it 'schedules sending all messages to be executed at the same time' do
        if lights.count < minimum_lights
          pending 'This test requires 3 or more lights tagged under Test'
          return
        end

        lifx.discover! { lights.count >= minimum_lights }

        lights.set_color(white, duration: 0)
        sleep 1

        msgs = []
        udp.add_observer(self, :message_received) do |message: nil, ip: nil, transport: nil|
          msgs << message if message.payload.is_a?(Protocol::Light::SetWaveform)
        end
        udp.listen

        lifx.sync do
          lights.each do |light|
            light.pulse(LIFX::Color.hsb(rand(360), 1, 1), period: 1)
          end
        end

        expect(msgs.count).to eq lights.count
        expect(msgs.map(&:at_time).uniq.count).to eq 1

        flush
      end
    end
  end
end
