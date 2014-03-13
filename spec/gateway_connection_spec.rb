require 'spec_helper'

module LIFX
  describe GatewayConnection do
    subject do
      GatewayConnection.new
    end

    let(:message) { double(Message).tap { |m| m.stub(:is_a?).and_return(true); m.stub(:pack) } }
    let(:ip) { '127.0.0.1' }
    let(:port) { 35003 }

    after do
      subject.close
    end

    context 'write queue resiliency' do
      it 'does not send if there is no available connection' do
        expect(subject).to_not receive(:actually_write)
        subject.write(message)
        expect { subject.flush(timeout: 0.5) }.to raise_error(Timeout::Error)
      end

      it 'sends over UDP if TCP is not available' do
        subject.connect_udp(ip, port)
        expect(subject.best_transport).to be_instance_of(Transport::UDP)
      end

      it 'pushes message back into queue if unable to write' do
        subject.connect_udp(ip, port)
        expect(subject).to receive(:actually_write).and_return(false, true)
        subject.write(message)
        subject.flush
      end
    end
  end
end
