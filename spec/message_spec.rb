require 'spec_helper'

describe LIFX::Message do
  context 'unpacking' do
    let(:data) { "\x39\x00\x00\x34\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x31\x6c\x69\x66\x78\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x67\x00\x00\x00\x00\x01\x00\x00\xff\xff\xff\xff\xac\x0d\xc8\x00\x00\x00\x00\x00\x80\x3f\x00\x00\x00".b }
    let(:msg) { LIFX::Message.unpack(data) }

    it 'unpacks without errors' do
      msg.should_not be_nil
    end

    it 'returns the correct frame data' do
      msg.msg_size.should == 57
      msg.protocol.should == 1024
      msg.addressable?.should == true
    end

    it 'returns the correct address data' do
      msg.raw_site.should == '1lifx1'
      msg.raw_target.should == "\x00" * 8
    end

    it 'has correct ProtocolPath data' do
      msg.path.should be_instance_of(LIFX::ProtocolPath)
      msg.path.site_id.should == '316c69667831'
      msg.path.tag_ids.should == []
      msg.path.device_id.should == nil
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

  context 'packing' do
    context 'no attributes' do
      let(:msg) { LIFX::Message.new }

      it 'throws an exception' do
        expect { msg.pack }.to raise_error(LIFX::Message::NoPayload)
      end
    end

    context 'no path' do
      let(:msg) { LIFX::Message.new(payload: LIFX::Protocol::Device::SetPower.new) }

      it 'throws an exception' do
        expect { msg.pack }.to raise_error(LIFX::Message::NoPath)
      end
    end

    context 'passed in via hash' do
      let(:msg) do
        LIFX::Message.new({
          path: LIFX::ProtocolPath.new(tagged: false, raw_target: "abcdefgh"),
          at_time: 9001,
          payload: LIFX::Protocol::Wifi::SetAccessPoint.new(
            interface: 1,
            ssid: "who let the dogs out",
            pass: "woof, woof, woof woof!",
            security: 1
          )
        })
      end

      it 'sets the size' do
        msg.msg_size.should == 134
      end

      it 'packs correctly' do
        msg.pack.should == "\x86\x00\x00\x14\x00\x00\x00\x00abcdefgh\x00\x00\x00\x00\x00\x00\x00\x00)#\x00\x00\x00\x00\x00\x001\x01\x00\x00\x01who let the dogs out\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00woof, woof, woof woof!\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01".b
        unpacked = LIFX::Message.unpack(msg.pack)
        msg.protocol.should == 1024
        msg.path.tagged?.should == false
        msg.addressable?.should == true
        msg.path.raw_target.should == 'abcdefgh'
        msg.at_time.should == 9001
        msg.type.should == 305
        msg.payload.class.should == LIFX::Protocol::Wifi::SetAccessPoint
        msg.payload.interface.should == 1
        msg.payload.ssid.should == "who let the dogs out"
        msg.payload.pass.should == "woof, woof, woof woof!"
        msg.payload.security.should == 1
      end
    end

    context 'packing with tags' do
      let(:msg) do
        LIFX::Message.new({
          path: LIFX::ProtocolPath.new(tag_ids: [0,1]),
          at_time: 9001,
          payload: LIFX::Protocol::Device::GetTime.new
        })
      end

      let(:unpacked) { LIFX::Message.unpack(msg.pack) }

      it 'packs the tag correctly' do
        msg.pack.should == "$\x00\x004\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00)#\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00".b
      end

      it 'sets tagged' do
        unpacked.path.tagged?.should == true
      end

      it 'sets tags' do
        unpacked.path.tag_ids.should == [0, 1]
      end

      it 'device should be nil' do
        unpacked.path.device_id.should == nil
      end
    end

    context 'packing with device' do
      let(:msg) do
        LIFX::Message.new({
          path: LIFX::ProtocolPath.new(device_id: '0123456789ab', site_id: '0' * 12),
          at_time: 9001,
          payload: LIFX::Protocol::Device::GetTime.new
        })
      end

      let(:unpacked) { LIFX::Message.unpack(msg.pack) }

      it 'packs the tag correctly' do
        msg.pack.should == "$\x00\x00\x14\x00\x00\x00\x00\x01#Eg\x89\xAB\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00)#\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00".b
      end

      it 'sets tagged to false' do
        unpacked.path.tagged?.should == false
      end

      it 'sets device' do
        unpacked.path.device_id.should == '0123456789ab'
      end

      it 'tags should be nil' do
        unpacked.path.tag_ids.should == nil
      end
    end
  end
end
