require 'spec_helper'

module LIFX
  describe ProtocolPath do
    describe 'initializing from raw data' do
      subject do
        ProtocolPath.new(raw_site: '1lifx1', raw_target: target, tagged: tagged)
      end

      context 'device target' do
        let(:target) { "\xAB\xCD\xEF\x12\x34\x56\x00\x00" }
        let(:tagged) { false }

        it 'returns site_id in hex' do
          expect(subject.site_id).to eq '316c69667831'
        end

        it 'returns device_id in hex' do
          expect(subject.device_id).to eq 'abcdef123456'
        end

        it 'returns tagged as false' do
          expect(subject).not_to be_tagged
        end

        it 'returns nil for tag_ids' do
          expect(subject.tag_ids).to be_nil
        end
      end

      context 'tagged target' do
        let(:target) { "\x03\x00\x00\x00\x00\x00\x00\x00" }
        let(:tagged) { true }

        it 'returns site_id in hex' do
          expect(subject.site_id).to eq '316c69667831'
        end

        it 'returns device_id as nil' do
          expect(subject.device_id).to be_nil
        end

        it 'returns tagged as true' do
          expect(subject).to be_tagged
        end

        it 'returns the tag_ids' do
          expect(subject.tag_ids).to eq [0, 1]
        end
      end
    end

    describe 'initializing from strings' do
      context 'device target' do
        subject do
          ProtocolPath.new(site_id: '316c69667831', device_id: 'abcdef123456')
        end

        it 'sets raw_site correctly' do
          expect(subject.raw_site).to eq '1lifx1'
        end

        it 'sets raw_target correctly' do
          expect(subject.raw_target).to eq "\xAB\xCD\xEF\x12\x34\x56\x00\x00".b
        end

        it 'sets tagged to false' do
          expect(subject).to_not be_tagged
        end
      end

      context 'tagged target' do
        subject do
          ProtocolPath.new(site_id: '316c69667831', tag_ids: [0, 1])
        end

        it 'sets raw_site properly' do
          expect(subject.raw_site).to eq '1lifx1'
        end

        it 'sets raw_target correctly' do
          expect(subject.raw_target).to eq "\x03\x00\x00\x00\x00\x00\x00\x00".b
        end

        it 'returns tagged as true' do
          expect(subject).to be_tagged
        end
      end

      context 'tagged target with no site' do
        subject { ProtocolPath.new(tagged: true) }

        it 'raw_site should be null string' do
          expect(subject.raw_site).to eq "\x00\x00\x00\x00\x00\x00".b
        end

        it 'sets raw_target correctly' do
          expect(subject.raw_target).to eq "\x00\x00\x00\x00\x00\x00\x00\x00".b
        end

        it 'returns tagged as true' do
          expect(subject).to be_tagged
        end
      end
    end
  end
end
