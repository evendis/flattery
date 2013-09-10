require 'spec_helper.rb'

describe Flattery::ValueProvider do

  let(:provider_class) do
    class ::ValueProviderHarness < Category
      include Flattery::ValueProvider
    end
    ValueProviderHarness
  end

  subject { provider_class }

  its(:included_modules) { should include(Flattery::ValueProvider) }
  its(:value_provider_options) { should be_a(Flattery::ValueProvider::Settings) }

  describe "#after_update" do
    let(:processor_class) { Flattery::ValueProvider::Processor }
    it "should not be called when record created" do
      processor_class.any_instance.should_receive(:after_update).never
      provider_class.create!
    end
    it "should be called when record updated" do
      instance = provider_class.create!
      processor_class.any_instance.should_receive(:after_update).and_return(true)
      instance.save
    end
  end

end
