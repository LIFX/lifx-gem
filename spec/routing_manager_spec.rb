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
  end
end
