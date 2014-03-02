require 'spec_helper'

module LIFX
  describe "tags", integration: true do
    it 'Clearing, setting and using tags' do
      light.add_tag('Test')
      wait { light.tags.should include('Test') }

      lifx.lights.with_tag('Test').turn_on
      color = Color.hsb(rand(360), 0.3, 0.3)

      lifx.lights.with_tag('Test').set_color(color) 
      sleep 1 # Set messages are scheduled 250ms if no at_time is set
              # It also returns the current light state rather than the final state
      light.refresh
      wait { light.color.should == color }

      light.remove_tag('Test')
      wait { light.tags.should_not include('Test') }
    end

    it 'deletes tags when no longer assigned to a light' do
      # This is difficult because not all lights with that tag are
      # guaranteed to be online.
      pending
    end
  end
end
