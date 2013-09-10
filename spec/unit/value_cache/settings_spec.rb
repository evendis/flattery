require 'spec_helper.rb'

describe Flattery::ValueCache::Settings do
  let(:settings_class) { Flattery::ValueCache::Settings }
  let(:settings) { cache_class.value_cache_options }
  subject { settings }

  context "with a standard belongs_to association" do
    let(:cache_class) do
      class ::ValueCacheHarness < Note
        include Flattery::ValueCache
        flatten_value category: :name
      end
      ValueCacheHarness
    end
    context "before resolution" do
      it { should be_a(settings_class) }
      its(:raw_settings) { should eql([
        {from_entity: :category, to_entity: :name, as: nil}
      ]) }
      its(:resolved) { should be_false }
    end
    context "after resolution" do
      before { settings.settings }
      its(:resolved) { should be_true }
      its(:settings) { should eql({
        "category_name"=>{from_entity: :category, to_entity: :name, changed_on: ["category_id"]}
      }) }
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
      describe "parent" do
        let(:settings) { parent_cache_class.value_cache_options }
        its(:raw_settings) { should eql([
          {from_entity: :category, to_entity: :name, as: nil}
        ]) }
      end
      describe "child" do
        let(:settings) { child_cache_class.value_cache_options }
        its(:raw_settings) { should eql([
          {from_entity: :category, to_entity: :name, as: nil},
          {from_entity: :country, to_entity: :name, as: nil}
        ]) }
      end
    end
    context "after resolution" do
      before { parent_cache_class.value_cache_options.settings && child_cache_class.value_cache_options.settings}
      describe "parent" do
        let(:settings) { parent_cache_class.value_cache_options }
        its(:resolved) { should be_true }
        its(:settings) { should eql({
          "category_name"=>{from_entity: :category, to_entity: :name, changed_on: ["category_id"]}
        }) }
      end
      describe "child" do
        let(:settings) { child_cache_class.value_cache_options }
        its(:resolved) { should be_true }
        its(:settings) { should eql({
          "category_name"=>{from_entity: :category, to_entity: :name, changed_on: ["category_id"]},
          "country_name"=>{from_entity: :country, to_entity: :name, changed_on: ["country_id"]}
        }) }
      end
    end
  end

end
