require 'spec_helper.rb'

describe Flattery::ValueProvider::Settings do
  describe '.value_provider_options' do
    subject(:value_provider_options) { provider_class.value_provider_options }

    context "with a standard has_many association" do
      let(:provider_class) do
        class ::ValueProviderHarness < Category
          include Flattery::ValueProvider
          push_flattened_values_for name: :notes, as: :category_name
        end
        ValueProviderHarness
      end
      context "before resolution" do
        it 'has expected unresolved settings' do
          expect(subject).to be_a(described_class)
          expect(subject.raw_settings).to eql([
            {from_entity: :name, to_entity: :notes, as: 'category_name', method: :update_all, batch_size: 0}
          ])
          expect(subject.resolved).to eql(false)
        end
      end
      context "after resolution" do
        before { subject.settings }
        it 'has expected resolved settings' do
          expect(subject).to be_a(described_class)
          expect(subject.settings).to eql({
            "name"=>{to_entity: :notes, as: :category_name, method: :update_all, background_with: nil, batch_size: 0}
          })
          expect(subject.resolved).to eql(true)
        end
      end
    end


    context "with provider that cannot correctly infer the cache column name" do
      let(:provider_class) do
        class ::ValueProviderHarness < Category
          include Flattery::ValueProvider
          push_flattened_values_for name: :bogative
        end
        ValueProviderHarness
      end
      context "before resolution" do
        it 'has expected unresolved settings' do
          expect(subject).to be_a(described_class)
          expect(subject.raw_settings).to eql([
            {from_entity: :name, to_entity: :bogative, as: nil, method: :update_all, batch_size: 0}
          ])
          expect(subject.resolved).to eql(false)
        end
      end
      context "after resolution" do
        before { subject.settings }
        it 'has expected resolved settings' do
          expect(subject).to be_a(described_class)
          expect(subject.settings).to eql({})
          expect(subject.resolved).to eql(true)
        end
      end
    end


    context "with inherited model definitions and ValueProvider defined in the parent" do
      let!(:parent_provider_class) do
        class ::ValueProviderHarness < Category
          include Flattery::ValueProvider
          push_flattened_values_for name: :notes, as: :category_name
        end
        ValueProviderHarness
      end
      let!(:child_provider_class) do
        class ::ChildValueProviderHarness < ::ValueProviderHarness
          push_flattened_values_for description: :notes, as: :category_description
        end
        ChildValueProviderHarness
      end
      context "before resolution" do
        context "for parent" do
          subject(:value_provider_options) { parent_provider_class.value_provider_options }
          it 'has expected unresolved settings' do
            expect(subject).to be_a(described_class)
            expect(subject.raw_settings).to eql([
              {from_entity: :name, to_entity: :notes, as: 'category_name', method: :update_all, batch_size: 0}
            ])
            expect(subject.resolved).to eql(false)
          end
        end
        context "for child" do
          subject(:value_provider_options) { child_provider_class.value_provider_options }
          it 'has expected unresolved settings' do
            expect(subject).to be_a(described_class)
            expect(subject.raw_settings).to eql([
              {from_entity: :name, to_entity: :notes, as: 'category_name', method: :update_all, batch_size: 0},
              {from_entity: :description, to_entity: :notes, as: 'category_description', method: :update_all, batch_size: 0}
            ])
            expect(subject.resolved).to eql(false)
          end
        end
      end
      context "after resolution" do
        before { parent_provider_class.value_provider_options.settings && child_provider_class.value_provider_options.settings }
        context "for parent" do
          subject(:value_provider_options) { parent_provider_class.value_provider_options }
          it 'has expected resolved settings' do
            expect(subject).to be_a(described_class)
            expect(subject.settings).to eql({
              "name"=>{to_entity: :notes, as: :category_name, method: :update_all, background_with: nil, batch_size: 0}
            })
            expect(subject.resolved).to eql(true)
          end
        end
        context "for child" do
          subject(:value_provider_options) { child_provider_class.value_provider_options }
          it 'has expected resolved settings' do
            expect(subject).to be_a(described_class)
            expect(subject.settings).to eql({
              "name"=>{to_entity: :notes, as: :category_name, method: :update_all, background_with: nil, batch_size: 0},
              "description"=>{to_entity: :notes, as: :category_description, method: :update_all, background_with: nil, batch_size: 0}
            })
            expect(subject.resolved).to eql(true)
          end
        end
      end
    end
  end
end
