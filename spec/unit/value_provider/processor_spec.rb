require 'spec_helper.rb'

describe Flattery::ValueProvider::Processor do
  let(:processor_class) { Flattery::ValueProvider::Processor }
  let(:processor) { processor_class.new }
  subject { processor }

  it { should respond_to(:before_update) }

end
