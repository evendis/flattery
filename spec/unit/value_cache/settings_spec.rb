require 'spec_helper.rb'

describe Flattery::ValueCache::Settings do
  describe '.value_cache_options' do
    subject(:value_cache_options) { cache_class.value_cache_options }

    context "with a standard belongs_to association" do
      let(:cache_class) do
        class ::ValueCacheHarness < Note
          include Flattery::ValueCache
          flatten_value category: :name
        end
        ValueCacheHarness
      end
      context "before resolution" do
        it 'has expected unresolved settings' do
          expect(subject).to be_a(described_class)
          expect(subject.raw_settings).to eql([
            {from_entity: :category, to_entity: :name, as: nil}
          ])
          expect(subject.resolved).to eql(false)
        end
      end
      context "after resolution" do
        before { subject.settings }
        it 'has expected resolved settings' do
          expect(subject).to be_a(described_class)
          expect(subject.settings).to eql({
            "category_name"=>{from_entity: :category, to_entity: :name, changed_on: ["category_id"]}
          })
          expect(subject.resolved).to eql(true)
        end
      end
    end

    context "with inherited model definitions and ValueCache defined in the parent" do
      let!(:parent_cache_class) do
        class ::ValueCacheHarness < Note
          include Flattery::ValueCache
          flatten_value category: :name
        end
        ValueCacheHarness
      end
      let!(:child_cache_class) do
        class ::ChildValueCacheHarness < ::ValueCacheHarness
          flatten_value country: :name
        end
        ChildValueCacheHarness
      end
      context "before resolution" do
        context "for parent" do
          subject { parent_cache_class.value_cache_options }
          it 'has expected unresolved settings' do
            expect(subject).to be_a(described_class)
            expect(subject.raw_settings).to eql([
              {from_entity: :category, to_entity: :name, as: nil}
            ])
            expect(subject.resolved).to eql(false)
          end
        end
        context "for child" do
          subject { child_cache_class.value_cache_options }
          it 'has expected unresolved settings' do
            expect(subject).to be_a(described_class)
            expect(subject.raw_settings).to eql([
              {from_entity: :category, to_entity: :name, as: nil},
              {from_entity: :country, to_entity: :name, as: nil}
            ])
            expect(subject.resolved).to eql(false)
          end
        end
      end
      context "after resolution" do
        before { parent_cache_class.value_cache_options.settings && child_cache_class.value_cache_options.settings}
        context "for parent" do
          subject { parent_cache_class.value_cache_options }
          it 'has expected resolved settings' do
            expect(subject).to be_a(described_class)
            expect(subject.settings).to eql({
              "category_name"=>{from_entity: :category, to_entity: :name, changed_on: ["category_id"]}
            })
            expect(subject.resolved).to eql(true)
          end
        end
        context "for child" do
          subject { child_cache_class.value_cache_options }
          it 'has expected resolved settings' do
            expect(subject).to be_a(described_class)
            expect(subject.settings).to eql({
              "category_name"=>{from_entity: :category, to_entity: :name, changed_on: ["category_id"]},
              "country_name"=>{from_entity: :country, to_entity: :name, changed_on: ["country_id"]}
            })
            expect(subject.resolved).to eql(true)
          end
        end
      end
    end
  end
end
