require 'spec_helper'

module LIFX
  describe RoutingTable do
    describe '#clear_stale_entries' do
      subject(:table) { RoutingTable.new }

      before do
        table.update_table(site_id: 'site', device_id: 'stale device', last_seen: Time.now - 305)
        table.update_table(site_id: 'site', device_id: 'recent device', last_seen: Time.now)
      end

      it 'clears only entries older than 5 minutes' do
        expect(table.entries.count).to eq(2)
        table.clear_stale_entries
        expect(table.entries.count).to eq(1)
        expect(table.entries.first.device_id).to eq('recent device')
      end
    end
  end
end
