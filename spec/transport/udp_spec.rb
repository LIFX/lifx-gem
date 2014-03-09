require 'spec_helper'

describe LIFX::Transport::UDP do
  subject do
    LIFX::Transport::UDP.new('localhost', 22222)
  end

  describe '#write' do
    let(:message) { double }
    let(:payload) { double }
    it 'writes a Message to specified host' do
      message.should_receive(:pack).and_return(payload)
      UDPSocket.any_instance.should_receive(:send).with(payload, 0, 'localhost', 22222)
      subject.write(message)
    end
  end

  describe '#listen' do
    let(:raw_message) { 'some binary data' }
    let(:message) { double }
    let(:socket) { UDPSocket.new }

    it 'listens to the specified socket data, unpacks it and notifies observers' do
      messages = []
      subject.add_observer(self) do |message:, ip:, transport:|
        messages << message
      end
      subject.listen

      LIFX::Message.should_receive(:unpack).with(raw_message).and_return(message)
      socket.send(raw_message, 0, 'localhost', 22222)
      sleep 0.01
      messages.should include(message)
    end

  end
end
