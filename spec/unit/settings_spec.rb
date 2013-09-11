require 'spec_helper.rb'

describe Flattery::Settings do
  let(:settings_class) { Flattery::Settings }
  let(:settings) { settings_class.new }
  subject { settings }

  describe "#initialize" do
    its(:klass) { should be_nil }
    its(:raw_settings) { should eql([]) }
    its(:resolved_settings) { should eql({}) }
    its(:resolved) { should be_false}
    context "when given class parameter" do
      let(:klass) { String }
      let(:settings) { settings_class.new(klass) }
      its(:klass) { should eql(klass) }
    end
  end

  def add_dummy_settings_values
    settings.raw_settings = [1,2,3,4]
    settings.resolved_settings = {a: :b}
    settings.resolved = true
    settings
  end

  describe "#reset!" do
    before do
      add_dummy_settings_values
      settings.reset!
    end
    its(:raw_settings) { should eql([]) }
    its(:resolved_settings) { should eql({}) }
    its(:resolved) { should be_false}
  end

  describe "#add_setting" do

    context "when given empty hash" do
      before { add_dummy_settings_values }
      it "should not do anything" do
        expect { settings.add_setting({}) }.to_not change { settings.raw_settings }.from([1,2,3,4])
      end
    end

    context "when given nil" do
      it "should cause a reset!" do
        settings.should_receive(:reset!)
        settings.add_setting(nil)
      end
    end

    context "when given options as Symbols" do
      before { settings.add_setting({category: :name}) }
      its(:raw_settings) { should eql([
        { from_entity: :category, to_entity: :name, as: nil }
      ]) }
      context "and then given another definition" do
        before { settings.add_setting({person: :email}) }
        its(:raw_settings) { should eql([
          { from_entity: :category, to_entity: :name, as: nil },
          { from_entity: :person, to_entity: :email, as: nil }
        ]) }
        context "and then reset with nil" do
          before { settings.add_setting nil }
          its(:raw_settings) { should eql([]) }
        end
      end
    end

    context "when optional :as specified as Symbols" do
      before { settings.add_setting({category: :name, as: :cat_name}) }
      its(:raw_settings) { should eql([
        { from_entity: :category, to_entity: :name, as: 'cat_name' }
      ]) }
    end

    context "when optional :method specified as Symbols" do
      before { settings.add_setting({category: :name, method: :my_custom_updater}) }
      its(:raw_settings) { should eql([
        { from_entity: :category, to_entity: :name, as: nil, method: :my_custom_updater }
      ]) }
    end

    context "when optional :background_with specified as Symbols" do
      before { settings.add_setting({category: :name, background_with: :delayed_job}) }
      its(:raw_settings) { should eql([
        { from_entity: :category, to_entity: :name, as: nil, background_with: :delayed_job }
      ]) }
    end

    context "when given options as String" do
      before { settings.add_setting({'category' => 'name'}) }
      its(:raw_settings) { should eql([
        { from_entity: :category, to_entity: :name, as: nil }
      ]) }
    end

    context "when optional :as specified as String" do
      before { settings.add_setting({'category' => 'name', 'as' => 'cat_name'}) }
      its(:raw_settings) { should eql([
        { from_entity: :category, to_entity: :name, as: 'cat_name' }
      ]) }
    end

  end

  describe "#settings" do
    context "when initialially not resolved" do
      it "should invoke resolve_settings!" do
        settings.should_receive(:resolve_settings!)
        settings.settings
      end
      it "should mark as resolved" do
        expect { settings.settings }.to change { settings.resolved }.from(false).to(true)
      end
    end
    context "when initialially resolved" do
      before { add_dummy_settings_values }
      it "should not invoke resolve_settings!" do
        settings.should_receive(:resolve_settings!).never
        settings.settings
      end
      it "should not change resolved status" do
        expect { settings.settings }.to_not change { settings.resolved }.from(true)
      end
    end
  end

end
