require 'spec_helper'

module LIFX
  describe RoutingManager do
    describe '#tags_for_device_id' do
      subject(:manager) { RoutingManager.new(context: double) }

      before do
        ['Some label', 'Another label', 'Much label'].each_with_index do |lbl, i|
          manager.tag_table.update_table(site_id: 'site', tag_id: i, label: lbl)
        end

        manager.routing_table
               .update_table(site_id: 'site', device_id: 'device', tag_ids: [0, 2])
      end

      it 'resolves tags' do
        tags = manager.tags_for_device_id('device')
        expect(tags).to eq ['Some label', 'Much label']
      end
    end
  end
end
