require 'spec_helper'

module LIFX
  describe "tags", integration: true do
    it 'Clearing, setting and using tags' do
      light.add_tag('Test')
      wait { light.tags.should include('Test') }

      test_tag = lights.with_tag('Test')
      test_tag.turn_on
      color = Color.hsb(rand(360), 0.3, 0.3)
      test_tag.set_color(color, duration: 0) 
      flush
      sleep 1 # Set messages are scheduled 250ms if no at_time is set
              # It also returns the current light state rather than the final state
      light.refresh
      wait { light.color.should == color }

      light.remove_tag('Test')
      flush
      wait { light.tags.should_not include('Test') }
    end

    it 'deletes tags when no longer assigned to a light' do
      light.add_tag('TempTag')
      light.remove_tag('TempTag')

      wait { lifx.unused_tags.should include('TempTag') }
      lifx.purge_unused_tags!

      wait { lifx.unused_tags.should be_empty }
    end
  end
end
