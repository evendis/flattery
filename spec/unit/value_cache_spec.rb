require 'spec_helper.rb'

describe Flattery::ValueCache do

  let(:resource_class) do
    class ::ValueCacheHarness < Note
      include Flattery::ValueCache
    end
    ValueCacheHarness
  end

  describe "##included_modules" do
    subject { resource_class.included_modules }
    it { should include(Flattery::ValueCache) }
  end

  describe "#before_save" do
    let(:processor_class) { Flattery::ValueCache::Processor }
    it "should be called when record created" do
      processor_class.any_instance.should_receive(:before_save).and_return(true)
      resource_class.create!
    end
    it "should be called when record updated" do
      instance = resource_class.create!
      processor_class.any_instance.should_receive(:before_save).and_return(true)
      instance.save
    end
  end

  describe "##value_cache_options" do

    subject { resource_class.value_cache_options }

    context "when set to empty" do
      before { resource_class.flatten_value({}) }
      it { should be_empty }
    end

    context "when reset with nil" do
      before { resource_class.flatten_value category: :name }
      it "should clear all settings" do
        expect {
          resource_class.flatten_value nil
        }.to change {
          resource_class.value_cache_options
        }.to({})
      end
    end

    context "when set by association name and attribute value" do
      before { resource_class.flatten_value category: :name }
      it { should eql({
        settings: [{
          association_name: :category,
          association_method: :name,
          as: nil
        }],
        resolved: nil
      }) }
      context "and then given another definition" do
        before { resource_class.flatten_value person: :email }
        it { should eql({
          settings: [{
            association_name: :category,
            association_method: :name,
            as: nil
          },{
            association_name: :person,
            association_method: :email,
            as: nil
          }],
          resolved: nil
        }) }
        context "and then reset with nil" do
          before { resource_class.flatten_value nil }
          it { should eql({}) }
        end
      end
    end

    context "when given a cache column override" do
      before { resource_class.flatten_value category: :name, as: :cat_name }
      it { should eql({
        settings: [{
          association_name: :category,
          association_method: :name,
          as: 'cat_name'
        }],
        resolved: nil
      }) }
    end

    context "when set using Strings" do
      before { resource_class.flatten_value 'category' => 'name', 'as' => 'cat_name' }
      it { should eql({
        settings: [{
          association_name: :category,
          association_method: :name,
          as: 'cat_name'
        }],
        resolved: nil
      }) }
    end

  end

end
