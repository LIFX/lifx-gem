require 'spec_helper'

module LIFX
  describe LightCollection do
    subject(:collection) { LightCollection.new(context: double) }

    describe '#with_id' do
      let(:light) { double(Light, id: 'id') }
      before { allow(collection).to receive(:lights).and_return([light]) }

      it 'returns a Light with matching id' do
        expect(collection.with_id('id')).to eq light
      end

      it 'returns nil when none matches' do
        ret = collection.with_id('wrong id')
        expect(ret).to eq nil
      end
    end

    describe '#with_label' do
      let(:light) { double(Light, label: 'label') }
      before { allow(collection).to receive(:lights).and_return([light]) }

      it 'returns a Light with matching label' do
        expect(collection.with_label('label')).to eq light
      end

      it 'returns nil' do
        ret = collection.with_label('wrong label')
        expect(ret).to eq nil
      end
    end
  end
end
