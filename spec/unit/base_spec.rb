require 'spec_helper.rb'

class FlatteryTestHarness
  include Flattery
end

describe Flattery do

  let(:resource_class) { FlatteryTestHarness }
  let(:resource) { resource_class.new }
  it { should_not be_nil }

end