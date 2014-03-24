require 'spec_helper'

module LIFX
  describe Color do
    let(:default_kelvin) { 3500 }

    describe '.rgb' do
      context 'translating from RGB' do
        shared_examples 'translating color' do |name, rgb, expected|
          it "translates #{name} correctly" do
            translation = Color.rgb(*rgb).to_a
            expect(translation).to eq [*expected, default_kelvin]
          end
        end

        it_behaves_like 'translating color', 'red',    [255, 0, 0],     [0, 1, 1]
        it_behaves_like 'translating color', 'yellow', [255, 255, 0],   [60, 1, 1]
        it_behaves_like 'translating color', 'green',  [0, 255, 0],     [120, 1, 1]
        it_behaves_like 'translating color', 'cyan',   [0, 255, 255],   [180, 1, 1]
        it_behaves_like 'translating color', 'blue',   [0, 0, 255],     [240, 1, 1]
        it_behaves_like 'translating color', 'white',  [255, 255, 255], [0, 0, 1]
        it_behaves_like 'translating color', 'black',  [0, 0, 0],       [0, 0, 0]
      end
    end
  end
end
