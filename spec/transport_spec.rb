require 'spec_helper'

describe LIFX::Transport do
  # Transport handles communicating to the bulbs
  # UDP, TCP, Cloud

  describe 'initialize' do
    it 'takes an host and port' do
      transport = LIFX::Transport.new('127.0.0.1', 31_337)
      expect(transport.host).to eq '127.0.0.1'
      expect(transport.port).to eq 31_337
    end
  end
end
