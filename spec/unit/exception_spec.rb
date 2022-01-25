require 'spec_helper'

describe "Flattery Exceptions" do
  [
    Flattery::Error,
    Flattery::CacheColumnInflectionError
  ].each do |exception_class|
    describe exception_class do
      subject { raise exception_class.new("test") }
      it "raises correctly" do
        expect { subject }.to raise_error(exception_class)
      end
    end
  end
end
