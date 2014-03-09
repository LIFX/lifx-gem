require 'spec_helper'

module LIFX
  describe RoutingManager do
    describe '#tags_for_device_id' do
      subject do
        RoutingManager.new(context: double)
      end

      before do
        subject.tag_table.update_table(site_id: 'site', tag_id: 0, label: 'Some label')
        subject.tag_table.update_table(site_id: 'site', tag_id: 1, label: 'Another label')
        subject.tag_table.update_table(site_id: 'site', tag_id: 2, label: 'Much label')
        subject.routing_table.update_table(site_id: 'site', device_id: 'device', tag_ids: [0,2])
      end

      it 'resolves tags' do
        subject.tags_for_device_id('device').should == ['Some label', 'Much label']
      end
    end

    describe '#persist_cache / #read_cache' do
      let(:path) { Tempfile.new('non_existent_cache').path }
      subject do
        RoutingManager.new(context: double, cache_path: path)
      end

      it 'persists to a file and loads correctly' do
        subject.routing_table.update_table(site_id: 'site', device_id: 'device')
        subject.tag_table.update_table(tag_id: 1, site_id: 'site', label: 'tag')
        File.should_receive(:open).with(path, 'w').and_call_original
        subject.send(:persist_cache, path)

        rm = RoutingManager.new(context: double, cache_path: path)
        rm.routing_table.site_id_for_device_id('device').should == 'site'
        rm.tag_table.entry_with(tag_id: 1).label.should == 'tag'
      end
    end
  end
end
