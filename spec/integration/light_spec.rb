require 'spec_helper'

module LIFX
  describe Light, integration: true do
    describe '#set_power' do
      it 'sets the power of the light asynchronously' do
        light.set_power(:off)
        wait { expect(light).to be_off }
        light.set_power(:on)
        wait { expect(light).to be_on }
      end
    end

    describe '#set_power!' do
      it 'sets the power of the light synchronously' do
        light.set_power!(:off)
        expect(light).to be_off
        light.set_power!(:on)
        expect(light).to be_on
      end
    end

    describe '#set_color' do
      let(:color) { Color.hsb(rand(360), rand, rand) }

      it 'sets the color of the light asynchronously' do
        light.set_color(color, duration: 0)
        sleep 1
        light.refresh
        wait { expect(light.color).to be_similar_to(color) }
      end
    end

    describe '#set_label' do
      let(:label) { light.label.sub(/\d+|$/, rand(100).to_s) }

      it 'sets the label of the light synchronously' do
        light.set_label(label)
        expect(light.label).to eq label
      end
    end
  end
end
