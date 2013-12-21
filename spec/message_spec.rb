require 'spec_helper'

describe LIFX::Message do
  context 'unpacking' do
    let(:data) { "\x39\x00\x00\x34\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x31\x6c\x69\x66\x78\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x67\x00\x00\x00\x00\x01\x00\x00\xff\xff\xff\xff\xac\x0d\xc8\x00\x00\x00\x00\x00\x80\x3f\x00\x00\x00".force_encoding(Encoding::BINARY) }
    let(:msg) { LIFX::Message.unpack(data) }

    it 'unpacks without errors' do
      msg.should_not be_nil
    end

    it 'returns the correct frame data' do
      msg.msg_size.should == 57
      msg.protocol.should == 1024
      msg.addressable?.should == true
      msg.tagged?.should == true
    end

    it 'returns the correct address data' do
      msg.site.should == '1lifx1'
      msg.target.should == "\x00" * 8
    end

    it 'returns the correct metadata' do
      msg.at_time.should == 0
      msg.type.should == 103
    end

    let(:payload) { msg.payload }
    it 'returns the payload' do
      payload.class.should == LIFX::Protocol::Light::SetWaveform
      payload.stream.should == 0
      payload.transient.should be_true
      payload.color.hue.should == 0
      payload.color.saturation.should == 65535
      payload.color.brightness.should == 65535
      payload.color.kelvin.should == 3500
      payload.period.should == 200
      payload.cycles.should == 1.0
      payload.duty_cycle.should == 0
      payload.waveform.should == 0
    end

    it 'repacks to the same data' do
      msg.pack.should == data
    end
  end
end
