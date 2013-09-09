require 'spec_helper.rb'

class FlatteryValueCacheTestHarness < Note
  include Flattery::ValueCache
end

describe Flattery::ValueCache do

  let(:resource_class) { FlatteryValueCacheTestHarness }
  after { resource_class.value_cache_options = {} }

  describe "##included_modules" do
    subject { resource_class.included_modules }
    it { should include(Flattery::ValueCache) }
  end

  describe "##value_cache_options" do
    before { resource_class.flatten_value flatten_value_options }
    subject { resource_class.value_cache_options }

    context "when set to empty" do
      let(:flatten_value_options) { {} }
      it { should be_empty }
    end

    context "when reset with nil" do
      let(:flatten_value_options) { {category: :name} }
      it "should clear all settings" do
        expect {
          resource_class.flatten_value nil
        }.to change {
          resource_class.value_cache_options
        }.to({})
      end
    end

    context "with simple belongs_to association" do

      context "when set by association name and attribute value" do
        let(:flatten_value_options) { {category: :name} }
        it { should eql({
          "category_name" => {
            association_name: :category,
            association_method: :name,
            changed_on: ["category_id"]
          }
        }) }
      end

      context "when given a cache column override" do
        let(:flatten_value_options) { {category: :name, as: :cat_name} }
        it { should eql({
          "cat_name" => {
            association_name: :category,
            association_method: :name,
            changed_on: ["category_id"]
          }
        }) }
      end

      context "when set using Strings" do
        let(:flatten_value_options) { {'category' => 'name', 'as' => 'cat_name'} }
        it { should eql({
          "cat_name" => {
            association_name: :category,
            association_method: :name,
            changed_on: ["category_id"]
          }
        }) }
      end

      context "when set by association name and invalid attribute value" do
        let(:flatten_value_options) { {category: :bogative} }
        it { should be_empty }
      end

    end

    context "with a belongs_to association having non-standard primary and foreign keys" do

      context "when set by association name and attribute value" do
        let(:flatten_value_options) { {person: :email} }
        it { should eql({
          "person_email" => {
            association_name: :person,
            association_method: :email,
            changed_on: ["person_name"]
          }
        }) }
      end

      context "when set by association name and invalid attribute value" do
        let(:flatten_value_options) { {person: :bogative} }
        it { should be_empty }
      end

    end


  end

  describe "#resolve_value_cache" do
    it "should be called when record created" do
      resource_class.any_instance.should_receive(:resolve_value_cache).and_return(true)
      resource_class.create!
    end
    it "should be called when record updated" do
      instance = resource_class.create!
      instance.should_receive(:resolve_value_cache).and_return(true)
      instance.save
    end
  end

  describe "#before_save" do
    let!(:resource) { resource_class.create }

    context "with simple belongs_to associations with cached values" do
      before { resource_class.flatten_value category: :name }
      let!(:category) { Category.create(name: 'category_a') }

      context "when association is changed by id" do
        it "should cache the new value" do
          expect {
            resource.update_attributes(category_id: category.id)
          }.to change {
            resource.category_name
          }.from(nil).to(category.name)
        end
      end
      context "when already set" do
        before { resource.update_attributes(category_id: category.id) }
        context "then set to nil" do
          it "should cache the new value" do
            expect {
              resource.update_attributes(category_id: nil)
            }.to change {
              resource.category_name
            }.from(category.name).to(nil)
          end
        end
        context "and associated record is destroyed" do
          before { category.destroy }
          it "should not recache the value when other values updated" do
            expect {
              resource.update_attributes(name: 'a new name')
            }.to_not change {
              resource.category_name
            }.from(category.name)
          end
        end
      end

    end
  end

end
