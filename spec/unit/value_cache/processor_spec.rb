require 'spec_helper.rb'

describe Flattery::ValueCache::Processor do
  let(:processor_class) { Flattery::ValueCache::Processor }
  let(:processor) { processor_class.new }
  subject { processor }

  it { should respond_to(:before_save) }

end
