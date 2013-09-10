require 'spec_helper.rb'

class FlatteryValueProviderTestHarness < Category
  include Flattery::ValueProvider
end

describe Flattery::ValueProvider do

  let(:resource_class) { FlatteryValueProviderTestHarness }
  after { resource_class.value_provider_options = {} }

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
    before { resource_class.push_flattened_values_for push_flattened_values_for_options }
    subject { resource_class.value_provider_options }

    context "when set to empty" do
      let(:push_flattened_values_for_options) { {} }
      it { should be_empty }
    end

    context "when reset with nil" do
      let(:push_flattened_values_for_options) { {name: :notes} }
      it "should clear all settings" do
        expect {
          resource_class.push_flattened_values_for nil
        }.to change {
          resource_class.value_provider_options
        }.to({})
      end
    end

    context "with simple has_many association" do

      context "when set by association name and attribute value" do
        let(:push_flattened_values_for_options) { {name: :notes} }
        it { should eql({
          "name" => {
            association_name: :notes,
            cached_attribute_name: :inflect,
            method: :update_all
          }
        }) }
      end

      context "when given a cache column override" do
        let(:push_flattened_values_for_options) { {name: :notes, as: :category_name} }
        it { should eql({
          "name" => {
            association_name: :notes,
            cached_attribute_name: :category_name,
            method: :update_all
          }
        }) }
      end

      context "when set by association name and invalid attribute value" do
        let(:push_flattened_values_for_options) { {name: :bogative} }
        it { should be_empty }
      end

    end
  end

end
