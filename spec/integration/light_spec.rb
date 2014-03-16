require 'spec_helper'

module LIFX
  describe Light, integration: true do
    describe '#set_power' do
      it "sets the power of the light asynchronously" do
        light.set_power(0)
        wait { light.off?.should == true }
        light.set_power(1)
        wait { light.on?.should == true }
      end
    end

    describe '#set_power!' do
      it "sets the power of the light synchronously" do
        light.set_power!(0)
        light.off?.should == true
        light.set_power!(1)
        light.on?.should == true
      end
    end

    describe '#set_color' do
      it "sets the color of the light asynchronously" do
        color = Color.hsb(rand(360), rand, rand)
        light.set_color(color, duration: 0)
        sleep 1
        light.refresh
        wait { light.color.should == color }
      end
    end

    describe '#set_label' do
      it "sets the label of the light synchronously" do
        label = light.label.sub(/\d+|$/, rand(100).to_s)
        light.set_label(label)
        light.label.should == label
      end
    end


  end
end
