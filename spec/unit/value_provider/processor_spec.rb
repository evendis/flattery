require 'spec_helper.rb'

# Test caching in a range of actual scenarios
describe Flattery::ValueProvider::Processor do
  let(:processor_class) { Flattery::ValueProvider::Processor }

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

  context "with a custom batch size" do
    let(:provider_class) do
      class ::ValueProviderHarness < Category
        include Flattery::ValueProvider
        push_flattened_values_for name: :notes, as: :category_name, batch_size: 10
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

  context "with a custom update method" do
    let(:provider_class) do
      class ::ValueProviderHarness < Category
        include Flattery::ValueProvider
        push_flattened_values_for name: :notes, as: :category_name, method: :my_updater_method
        def my_updater_method(attribute,new_value,association_name,target_attribute,batch_size)
          self.send(association_name).update_all(target_attribute => "#{new_value} (set by my_updater_method)")
        end
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
        }.from('category_a').to('new category name (set by my_updater_method)')
      end
    end
  end

  context "with delayed job support stubbed" do
    before do
      processor_class.any_instance.stub(:delay)
    end

    context "and background processing requested" do

      let(:provider_class) do
        class ::ValueProviderHarness < Category
          include Flattery::ValueProvider
          push_flattened_values_for name: :notes, as: :category_name, background_with: :delayed_job
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

      it "should update via delay" do
        processor = double()
        processor.should_receive(:apply_push)
        processor_class.any_instance.should_receive(:delay).and_return(processor)
        resource.update_attributes(name: 'new category name')
      end
    end
  end

  context "with delayed job support mocked" do
    before do
      processor_class.send(:define_method,:delay) { self }
    end
    after do
      processor_class.send(:undef_method,:delay)
    end

    context "and background processing requested" do

      let(:provider_class) do
        class ::ValueProviderHarness < Category
          include Flattery::ValueProvider
          push_flattened_values_for name: :notes, as: :category_name, background_with: :delayed_job
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

      it "should push the new cache value" do
        expect {
          resource.update_attributes(name: 'new category name')
        }.to change {
          target_a.reload.category_name
        }.from('category_a').to('new category name')
      end

    end
  end

end
