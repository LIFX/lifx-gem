require 'spec_helper'

module LIFX
  describe 'tags', integration: true do
    let(:color) { Color.hsb(rand(360), 0.3, 0.3) }

    specify 'Clearing, setting and using tags' do
      light.add_tag('Foo')
      expect(light.tags).to include('Foo')

      test_tag = lights.with_tag('Foo')
      test_tag.turn_on
      test_tag.set_color(color, duration: 0)
      flush
      sleep 1 # Set messages are scheduled 250ms if no at_time is set
              # It also returns the current light state rather than the
              # final state
      light.refresh
      wait { expect(light.color).to eq color }

      light.remove_tag('Foo')
      wait { expect(light.tags).not_to include('Foo') }
    end

    it 'deletes tags when no longer assigned to a light' do
      light.add_tag('TempTag')
      light.remove_tag('TempTag')
      expect(lifx.unused_tags).to include('TempTag')
      lifx.purge_unused_tags!
      expect(lifx.unused_tags).to be_empty
    end
  end
end
