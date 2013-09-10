require 'spec_helper.rb'

describe Flattery::ValueCache::Processor do
  let(:processor_class) { Flattery::ValueCache::Processor }
  let(:processor) { processor_class.new }
  subject { processor }

  it { should respond_to(:before_save) }

  describe "#resolved_options!" do

    context "with a standard belongs_to association" do
      let(:cache_class) do
        class ::ValueCacheHarness < Note
          include Flattery::ValueCache
          flatten_value category: :name
        end
        ValueCacheHarness
      end

      subject { processor.resolved_options!(cache_class) }
      it { should eql({
        'category_name' => {
          association_name: :category,
          association_method: :name,
          changed_on: ['category_id']
        }
      })}

    end

  end

end
