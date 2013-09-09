require 'spec_helper.rb'

class FlatteryValueProviderTestHarness < Category
  include Flattery::ValueProvider
end

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

describe Flattery::ValueProvider do

  let(:resource_class) { FlatteryValueProviderTestHarness }
  after { resource_class.value_provider_options = {} }

  describe "##included_modules" do
    subject { resource_class.included_modules }
    it { should include(Flattery::ValueProvider) }
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

  describe "#resolve_value_provision" do
    it "should not be called when record created" do
      resource_class.any_instance.should_receive(:resolve_value_provision).never
      resource_class.create!
    end
    it "should be called when record updated" do
      instance = resource_class.create!
      instance.should_receive(:resolve_value_provision).and_return(true)
      instance.save
    end
  end

  describe "#before_update" do

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
end
