require 'spec_helper'

module LIFX
  describe GatewayConnection do
    subject(:gateway) { GatewayConnection.new }

    let(:message) { double(Message, is_a?: true, pack: '') }
    let(:ip) { '127.0.0.1' }
    let(:port) { 35_003 }

    after { gateway.close }

    context 'write queue resiliency' do
      it 'does not send if there is no available connection' do
        expect(gateway).to_not receive(:actually_write)
        gateway.write(message)
        expect { gateway.flush(timeout: 0.5) }.to raise_error(Timeout::Error)
      end

      it 'pushes message back into queue if unable to write' do
        gateway.connect_udp(ip, port)
        expect(gateway).to receive(:actually_write).and_return(false, true)
        gateway.write(message)
        gateway.flush
      end
    end
  end
end
