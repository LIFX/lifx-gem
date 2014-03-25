require 'spec_helper'

module LIFX
  describe LightCollection do
    subject(:collection) { LightCollection.new(context: double) }

    describe '#with_id' do
      it 'returns a Light with matching id' do
        light = double(Light, id: 'id')
        collection.stub(lights: [light])
        expect(collection.with_id('id')).to eq light
      end

      it 'returns nil when none matches' do
        light = double(Light, id: 'id')
        collection.stub(lights: [light])
        ret = collection.with_id('wrong id')
        expect(ret).to eq nil
      end
    end

    describe '#with_label' do
      it 'returns a Light with matching label' do
        light = double(Light, label: 'label')
        collection.stub(lights: [light])
        expect(collection.with_label('label')).to eq light
      end

      it 'returns nil' do
        light = double(Light, label: 'label')
        collection.stub(lights: [light])
        ret = collection.with_label('wrong label')
        expect(ret).to eq nil
      end
    end
  end
end
