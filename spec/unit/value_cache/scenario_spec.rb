require 'spec_helper.rb'

class FlatteryValueCacheScenarioTestHarness < Note
  include Flattery::ValueCache
end

# Test caching in a range of actual scenarios
# TODO: refactor to eliminate dependency on shared model definitions
describe Flattery::ValueCache do

  let(:resource_class) { FlatteryValueCacheScenarioTestHarness }
  after { resource_class.value_cache_options = {} }

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