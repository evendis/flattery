require 'spec_helper.rb'

class NoteTestHarness < Note
  include Flattery::ValueCache
end

class CategoryTestHarness < Category
  include Flattery::ValueProvider
end

class PersonTestHarness < Person
  include Flattery::ValueProvider
  has_many :harness_notes, class_name: 'NoteTestHarness', primary_key: "username", foreign_key: "person_name", inverse_of: :person
end

# Test caching in a range of actual scenarios
# TODO: refactor to eliminate dependency on shared model definitions
describe Flattery::ValueProvider do

  context "with provider having simple has_many association and explicit cache_column name" do
    let(:provider_class) { CategoryTestHarness }
    let(:cache_class)    { NoteTestHarness }
    before do
      provider_class.push_flattened_values_for name: :notes, as: :category_name
      cache_class.flatten_value category: :name
    end
    after do
      provider_class.value_provider_options = {}
      cache_class.value_cache_options = {}
    end
    let!(:resource)       { provider_class.create(name: 'category_a') }
    let!(:target_a)       { cache_class.create(category_id: resource.id) }
    let!(:target_other_a) { cache_class.create }
    context "when cached value is updated" do
      it "should push the new cache value" do
        expect {
          resource.update_attributes(name: 'new category name')
        }.to change {
          target_a.reload.category_name
        }.from('category_a').to('new category name')
      end
    end
  end

  context "with provider that cannot correctly infer the cache column name" do
    let(:provider_class) { CategoryTestHarness }
    let(:cache_class)    { NoteTestHarness }
    before do
      provider_class.push_flattened_values_for name: :notes
      cache_class.flatten_value category: :name
    end
    after do
      provider_class.value_provider_options = {}
      cache_class.value_cache_options = {}
    end
    let!(:resource)       { provider_class.create(name: 'category_a') }
    let!(:target_a)       { cache_class.create(category_id: resource.id) }
    let!(:target_other_a) { cache_class.create }
    context "when cached value is updated" do
      it "should push the new cache value" do
        expect {
          resource.update_attributes(name: 'new category name')
        }.to raise_error(Flattery::CacheColumnInflectionError)
      end
    end
  end

  context "with provider having has_many association with cache name inflected via inverse relation" do
    let(:provider_class) { PersonTestHarness }
    let(:cache_class)    { NoteTestHarness }
    before do
      provider_class.push_flattened_values_for email: :notes
      cache_class.flatten_value person: :email
    end
    after do
      provider_class.value_provider_options = {}
      cache_class.value_cache_options = {}
    end
    let!(:resource)       { provider_class.create(username: 'user_a', email: 'email1') }
    let!(:target_a)       { cache_class.create(person_name: resource.username) }
    let!(:target_other_a) { cache_class.create }
    context "when cached value is updated" do
      it "should push the new cache value" do
        expect {
          resource.update_attributes(email: 'email2')
        }.to change {
          target_a.reload.person_email
        }.from('email1').to('email2')
      end
    end
  end

  context "with provider having has_many association with cache name inflected via inverse relation with custom cache column name" do
    let(:provider_class) { PersonTestHarness }
    let(:cache_class)    { NoteTestHarness }
    before do
      provider_class.push_flattened_values_for email: :harness_notes
      cache_class.flatten_value person: :email, as: :user_email
    end
    after do
      provider_class.value_provider_options = {}
      cache_class.value_cache_options = {}
    end
    let!(:resource)       { provider_class.create(username: 'user_a', email: 'email1') }
    let!(:target_a)       { cache_class.create(person_name: resource.username) }
    let!(:target_other_a) { cache_class.create }
    context "when cached value is updated" do
      it "should push the new cache value" do
        expect {
          resource.update_attributes(email: 'email2')
        }.to change {
          target_a.reload.user_email
        }.from('email1').to('email2')
      end
    end
  end

end