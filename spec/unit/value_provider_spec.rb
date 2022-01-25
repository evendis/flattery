require 'spec_helper.rb'

describe Flattery::ValueProvider do
  let(:provider_class) do
    class ::ValueProviderHarness < Category
      include Flattery::ValueProvider
    end
    ValueProviderHarness
  end

  subject { provider_class }

  it 'has the expected defaults' do
    expect(subject.included_modules).to include(Flattery::ValueProvider)
    expect(subject.value_provider_options).to be_a(Flattery::ValueProvider::Settings)
  end

  describe "#after_update" do
    let(:processor_class) { Flattery::ValueProvider::Processor }
    it "should not be called when record created" do
      expect_any_instance_of(processor_class).to_not receive(:after_update)
      provider_class.create!
    end
    it "should be called when record updated" do
      instance = provider_class.create!
      expect_any_instance_of(processor_class).to receive(:after_update).and_return(true)
      instance.save
    end
  end
end
