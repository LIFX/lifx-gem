require 'spec_helper'

module LIFX
  describe "tags", integration: true do
    it 'Clearing, setting and using tags' do
      light.tags.each do |tag_label|
        light.remove_tag(tag_label)
      end
      flush
      wait { light.tags.should be_empty }

      light.add_tag('Test')
      wait { light.tags.should include('Test') }

      lifx.lights.with_tag('Test').turn_on
      color = Color.hsb(rand(360), 0.3, 0.3)

      lifx.lights.with_tag('Test').set_color(color)
      sleep 1
      light.refresh
      wait { light.color.should == color }
    end
  end
end
