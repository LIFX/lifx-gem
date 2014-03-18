require 'spec_helper'

module LIFX
  describe Color do
    let(:default_kelvin) { 3500 }
    describe '.rgb' do
      context 'translating from RGB' do
        it 'translates red correctly' do
          c = Color.rgb(255, 0, 0)
          c.to_a.should == [0, 1, 1, default_kelvin]
        end

        it 'translates yellow correctly' do
          c = Color.rgb(255, 255, 0)
          c.to_a.should == [60, 1, 1, default_kelvin]
        end

        it 'translates green correctly' do
          c = Color.rgb(0, 255, 0)
          c.to_a.should == [120, 1, 1, default_kelvin]
        end

        it 'translates cyan correctly' do
          c = Color.rgb(0, 255, 255)
          c.to_a.should == [180, 1, 1, default_kelvin]
        end

        it 'translates blue correctly' do
          c = Color.rgb(0, 0, 255)
          c.to_a.should == [240, 1, 1, default_kelvin]
        end

        it 'translates white correctly' do
          c = Color.rgb(255, 255, 255)
          c.to_a.should == [0, 0, 1, default_kelvin]
        end

        it 'translates black correctly' do
          c = Color.rgb(0, 0, 0)
          c.to_a.should == [0, 0, 0, default_kelvin]
        end
      end
    end
  end
end
