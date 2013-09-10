require 'spec_helper.rb'

describe Flattery::ValueCache do

  let(:cache_class) do
    class ::ValueCacheHarness < Note
      include Flattery::ValueCache
    end
    ValueCacheHarness
  end

  subject { cache_class }

  its(:included_modules) { should include(Flattery::ValueCache) }
  its(:value_cache_options) { should be_a(Flattery::ValueCache::Settings) }

  describe "#before_save" do
    let(:processor_class) { Flattery::ValueCache::Processor }
    it "should be called when record created" do
      processor_class.any_instance.should_receive(:before_save).and_return(true)
      subject.create!
    end
    it "should be called when record updated" do
      instance = subject.create!
      processor_class.any_instance.should_receive(:before_save).and_return(true)
      instance.save
    end
  end

end
