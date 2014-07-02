require 'spec_helper'

describe LIFX::Message do
  context 'unpacking' do
    let(:data) do
      "\x39\x00\x00\x34\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x31" \
      "\x6c\x69\x66\x78\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x67\x00" \
      "\x00\x00\x00\x01\x00\x00\xff\xff\xff\xff\xac\x0d\xc8\x00\x00\x00\x00" \
      "\x00\x80\x3f\x00\x00\x00".b
    end
    let(:msg) { LIFX::Message.unpack(data) }

    it 'unpacks without errors' do
      expect(msg).not_to be_nil
    end

    it 'returns the correct frame data' do
      expect(msg.msg_size).to eq 57
      expect(msg.protocol).to eq 1024
      expect(msg).to be_addressable
    end

    it 'returns the correct address data' do
      expect(msg.raw_site).to eq '1lifx1'
      expect(msg.raw_target).to eq "\x00" * 8
    end

    it 'has correct ProtocolPath data' do
      expect(msg.path).to be_a(LIFX::ProtocolPath)
      expect(msg.path.site_id).to eq '316c69667831'
      expect(msg.path.tag_ids).to eq []
      expect(msg.path.device_id).to be_nil
    end

    it 'returns the correct metadata' do
      expect(msg.at_time).to eq 0
      expect(msg.type).to eq 103
    end

    let(:payload) { msg.payload }
    it 'returns the payload' do
      expect(payload.class).to eq LIFX::Protocol::Light::SetWaveform
      expect(payload.stream).to eq 0
      expect(payload.transient).to be_truthy
      expect(payload.color.hue).to eq 0
      expect(payload.color.saturation).to eq 65_535
      expect(payload.color.brightness).to eq 65_535
      expect(payload.color.kelvin).to eq 3_500
      expect(payload.period).to eq 200
      expect(payload.cycles).to eq 1.0
      expect(payload.skew_ratio).to eq 0
      expect(payload.waveform).to eq 0
    end

    it 'repacks to the same data' do
      expect(msg.pack).to eq data
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

      it 'defaults to null site and target' do
        unpacked = LIFX::Message.unpack(msg.pack)
        expect(unpacked.path.site_id).to eq('000000000000')
        expect(unpacked.path.device_id).to eq('000000000000')
      end
    end

    context 'passed in via hash' do
      let(:msg) do
        LIFX::Message.new({
          path: LIFX::ProtocolPath.new(tagged: false, raw_target: 'abcdefgh'),
          at_time: 9001,
          payload: LIFX::Protocol::Wifi::SetAccessPoint.new(
            interface: 1,
            ssid: 'who let the dogs out',
            pass: 'woof, woof, woof woof!',
            security: 1
          )
        })
      end
      # let(:unpacked) { LIFX::Message.unpack(msg.pack) }

      it 'sets the size' do
        expect(msg.msg_size).to eq 134
      end

      it 'packs correctly' do
        expect(msg.pack).to eq "\x86\x00\x00\x14\x00\x00\x00\x00abcdefgh\x00" \
                               "\x00\x00\x00\x00\x00\x00\x00)#\x00\x00\x00"   \
                               "\x00\x00\x001\x01\x00\x00\x01who let the "    \
                               "dogs out\x00\x00\x00\x00\x00\x00\x00\x00\x00" \
                               "\x00\x00\x00woof, woof, woof woof!\x00\x00"   \
                               "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" \
                               "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" \
                               "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" \
                               "\x00\x00\x00\x00\x00\x00\x00\x01".b
        expect(msg.protocol).to eq 1024
        expect(msg.path).not_to be_tagged
        expect(msg).to be_addressable
        expect(msg.path.raw_target).to eq 'abcdefgh'
        expect(msg.at_time).to eq 9001
        expect(msg.type).to eq 305
        expect(msg.payload.class).to eq LIFX::Protocol::Wifi::SetAccessPoint
        expect(msg.payload.interface).to eq 1
        expect(msg.payload.ssid).to eq 'who let the dogs out'
        expect(msg.payload.pass).to eq 'woof, woof, woof woof!'
        expect(msg.payload.security).to eq 1
      end
    end

    context 'packing with tags' do
      let(:msg) do
        LIFX::Message.new({
          path: LIFX::ProtocolPath.new(tag_ids: [0, 1]),
          at_time: 9001,
          payload: LIFX::Protocol::Device::GetTime.new
        })
      end

      let(:unpacked) { LIFX::Message.unpack(msg.pack) }

      it 'packs the tag correctly' do
        expect(msg.pack).to eq "$\x00\x004\x00\x00\x00\x00\x03\x00\x00\x00"   \
                               "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" \
                               "\x00)#\x00\x00\x00\x00\x00\x00\x04\x00\x00"   \
                               "\x00".b
      end

      it 'sets tagged' do
        expect(unpacked.path).to be_tagged
      end

      it 'sets tags' do
        expect(unpacked.path.tag_ids).to eq [0, 1]
      end

      it 'device should be nil' do
        expect(unpacked.path.device_id).to be_nil
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
        expect(msg.pack).to eq "$\x00\x00\x14\x00\x00\x00\x00\x01#Eg\x89\xAB" \
                               "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00)#"   \
                               "\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00".b
      end

      it 'sets tagged to false' do
        expect(unpacked.path).not_to be_tagged
      end

      it 'sets device' do
        expect(unpacked.path.device_id).to eq '0123456789ab'
      end

      it 'tags should be nil' do
        expect(unpacked.path.tag_ids).to be_nil
      end
    end
  end
end
