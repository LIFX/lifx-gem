require 'spec_helper'

describe LIFX::Transport::UDP, integration: true do
  subject(:udp) { LIFX::Transport::UDP.new(host, port) }

  let(:host) { 'localhost' }
  let(:message) { double }
  let(:port) { 45_828 }

  describe '#write' do
    let(:payload) { double }

    it 'writes a Message to specified host' do
      expect(message).to receive(:pack).and_return(payload)
      expect_any_instance_of(UDPSocket).to receive(:send)
                                           .with(payload, 0, host, port)
      udp.write(message)
    end
  end

  describe '#listen' do
    let(:raw_message) { 'some binary data' }
    let(:socket) { UDPSocket.new }

    it 'listens to the specified socket data, unpacks it and notifies observers' do
      messages = []
      udp.add_observer(self) do |message: nil, ip: nil, transport: nil|
        messages << message
      end
      udp.listen

      expect(LIFX::Message).to receive(:unpack)
                               .with(raw_message)
                               .and_return(message)
      socket.send(raw_message, 0, host, port)
      wait { expect(messages).to include(message) }
    end
  end
end
