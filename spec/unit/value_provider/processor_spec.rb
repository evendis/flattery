require 'spec_helper.rb'

describe Flattery::ValueProvider::Processor do
  let(:processor_class) { Flattery::ValueProvider::Processor }
  let(:processor) { processor_class.new }
  subject { processor }

  it { should respond_to(:before_update) }

  describe "#resolved_options!" do

    context "with a standard belongs_to association" do
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

      subject { processor.resolved_options!(provider_class) }
      it { should eql({
        'name' => {
          association_name: :notes,
          as: :category_name,
          method: :update_all
        }
      })}

    end

  end
end
