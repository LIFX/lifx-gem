require 'spec_helper'

module LIFX
  describe Light, integration: true do
    describe '#set_color' do
      it "sets the color of the light" do
        color = Color.hsb(rand(360), rand, rand)
        light.set_color(color, duration: 0)
        sleep 1
        light.refresh
        wait { light.color.should == color }
      end
    end

    describe '#set_label' do
      it "sets the label of the light" do
        label = light.label.sub(/\d+|$/, rand(100).to_s)
        light.set_label(label)
        sleep 1
        light.refresh
        wait { light.label.should == label }
      end
    end

  end
end
