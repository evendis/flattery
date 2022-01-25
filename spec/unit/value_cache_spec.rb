require 'spec_helper.rb'

describe Flattery::ValueCache do
  subject(:cache_class) do
    class ::ValueCacheHarness < Note
      include Flattery::ValueCache
    end
    ValueCacheHarness
  end

  it 'has the expected defaults' do
    expect(subject.included_modules).to include(Flattery::ValueCache)
    expect(subject.value_cache_options).to be_a(Flattery::ValueCache::Settings)
  end

  describe "#before_save" do
    let(:processor_class) { Flattery::ValueCache::Processor }
    it "is called when record created" do
      expect_any_instance_of(processor_class).to receive(:before_save).and_return(true)
      subject.create!
    end
    it "is called when record updated" do
      instance = subject.create!
      expect_any_instance_of(processor_class).to receive(:before_save).and_return(true)
      instance.save
    end
  end
end
