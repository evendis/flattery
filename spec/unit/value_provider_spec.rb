require 'spec_helper.rb'

describe Flattery::ValueProvider do

  let(:resource_class) do
    class ::ValueProviderHarness < Category
      include Flattery::ValueProvider
    end
    ValueProviderHarness
  end

  describe "##included_modules" do
    subject { resource_class.included_modules }
    it { should include(Flattery::ValueProvider) }
  end

  describe "#before_update" do
    let(:processor_class) { Flattery::ValueProvider::Processor }
    it "should not be called when record created" do
      processor_class.any_instance.should_receive(:before_update).never
      resource_class.create!
    end
    it "should be called when record updated" do
      instance = resource_class.create!
      processor_class.any_instance.should_receive(:before_update).and_return(true)
      instance.save
    end
  end

  describe "##value_provider_options" do

    subject { resource_class.value_provider_options }

    context "when set to empty" do
      before { resource_class.push_flattened_values_for({})}
      it { should be_empty }
    end

    context "when reset with nil" do
      before { resource_class.push_flattened_values_for name: :notes }
      it "should clear all settings" do
        expect {
          resource_class.push_flattened_values_for nil
        }.to change {
          resource_class.value_provider_options
        }.to({})
      end
    end

    context "when set by association name and attribute value" do
      before { resource_class.push_flattened_values_for name: :notes }
      it { should eql({
        settings: [{
          association_name: :notes,
          association_method: :name,
          method: :update_all,
          as: nil
        }],
        resolved: nil
      }) }
    end

    context "when given a cache column override" do
      before { resource_class.push_flattened_values_for name: :notes, as: :category_name }
      it { should eql({
        settings: [{
          association_name: :notes,
          association_method: :name,
          method: :update_all,
          as: 'category_name'
        }],
        resolved: nil
      }) }
    end

  end

end
