require 'spec_helper'

module LIFX
  describe ProtocolPath do
    describe 'initializing from raw data' do
      context 'device target' do
        subject do
          ProtocolPath.new(raw_site: "1lifx1", raw_target: "\xAB\xCD\xEF\x12\x34\x56\x00\x00", tagged: false)
        end

        it 'returns site_id in hex' do
          subject.site_id.should == "316c69667831"
        end

        it 'returns device_id in hex' do
          subject.device_id.should == 'abcdef123456'
        end

        it 'returns tagged as false' do
          subject.tagged?.should be_false
        end

        it 'returns nil for tag_ids' do
          subject.tag_ids.should == nil
        end
      end

      context 'tagged target' do
        subject do
          ProtocolPath.new(raw_site: "1lifx1", raw_target: "\x03\x00\x00\x00\x00\x00\x00\x00", tagged: true)
        end

        it 'returns site_id in hex' do
          subject.site_id.should == "316c69667831"
        end

        it 'returns device_id as nil' do
          subject.device_id.should == nil
        end

        it 'returns tagged as true' do
          subject.tagged?.should be_true
        end

        it 'returns the tag_ids' do
          subject.tag_ids.should == [0, 1]
        end
      end
    end

    describe 'initializing from strings' do
      context 'device target' do
        subject do
          ProtocolPath.new(site_id: "316c69667831", device_id: 'abcdef123456')
        end

        it 'sets raw_site correctly' do
          subject.raw_site.should == "1lifx1"
        end

        it 'sets raw_target correctly' do
          subject.raw_target.should == "\xAB\xCD\xEF\x12\x34\x56\x00\x00".b
        end

        it 'sets tagged to false' do
          subject.tagged?.should be_false
        end
      end

      context 'tagged target' do
        subject do
          ProtocolPath.new(site_id: "316c69667831", tag_ids: [0, 1])
        end

        it 'returns site_id in hex' do
          subject.raw_site.should == "1lifx1"
        end

        it 'sets raw_target correctly' do
          subject.raw_target.should == "\x03\x00\x00\x00\x00\x00\x00\x00".b
        end

        it 'returns tagged as true' do
          subject.tagged?.should be_true
        end
      end
    end

  end
end