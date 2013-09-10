require 'spec_helper.rb'

# Test caching in a range of actual scenarios
describe Flattery::ValueCache do

  context "with simple belongs_to associations with cached values" do
    let(:resource_class) do
      class ::ValueCacheHarness < Note
        include Flattery::ValueCache
        flatten_value category: :name
      end
      ValueCacheHarness
    end
    let!(:resource) { resource_class.create }

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