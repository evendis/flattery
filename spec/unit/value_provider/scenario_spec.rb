require 'spec_helper.rb'

# Test caching in a range of actual scenarios
describe Flattery::ValueProvider do

  after do
    Object.send(:remove_const, :ValueProviderHarness) if Object.constants.include?(:ValueProviderHarness)
    Object.send(:remove_const, :ValueCacheHarness) if Object.constants.include?(:ValueCacheHarness)
  end

  context "with provider having simple has_many association and explicit cache_column name" do
    let(:provider_class) do
      class ::ValueProviderHarness < Category
        include Flattery::ValueProvider
        push_flattened_values_for name: :notes, as: :category_name
      end
      ValueProviderHarness
    end

    let(:cache_class) do
      class ::ValueCacheHarness < Note
        include Flattery::ValueCache
        flatten_value category: :name
      end
      ValueCacheHarness
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
    let(:provider_class) do
      class ::ValueProviderHarness < Category
        include Flattery::ValueProvider
        push_flattened_values_for name: :notes
      end
      ValueProviderHarness
    end

    let(:cache_class) do
      class ::ValueCacheHarness < Note
        include Flattery::ValueCache
        flatten_value category: :name
      end
      ValueCacheHarness
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
    let(:provider_class) do
      class ::ValueProviderHarness < Person
        include Flattery::ValueProvider
        has_many :harness_notes, class_name: 'NoteTestHarness', primary_key: "username", foreign_key: "person_name", inverse_of: :person
        push_flattened_values_for email: :notes
      end
      ValueProviderHarness
    end

    let(:cache_class) do
      class ::ValueCacheHarness < Note
        include Flattery::ValueCache
        flatten_value person: :email
      end
      ValueCacheHarness
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
    let(:provider_class) do
      class ::ValueProviderHarness < Person
        include Flattery::ValueProvider
        has_many :harness_notes, class_name: 'ValueCacheHarness', primary_key: "username", foreign_key: "person_name", inverse_of: :person
        push_flattened_values_for email: :harness_notes
      end
      ValueProviderHarness
    end

    let(:cache_class) do
      class ::ValueCacheHarness < Note
        include Flattery::ValueCache
        flatten_value person: :email, as: :user_email
      end
      ValueCacheHarness
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
