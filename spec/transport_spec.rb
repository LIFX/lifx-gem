require 'spec_helper'

describe LIFX::Transport do
  # Transport handles communicating to the bulbs
  # UDP, TCP, Cloud

  describe 'initialize' do
    it 'takes an host and port' do
      transport = LIFX::Transport.new('127.0.0.1', 31337)
      transport.host.should == '127.0.0.1'
      transport.port.should == 31337
    end
  end
end
