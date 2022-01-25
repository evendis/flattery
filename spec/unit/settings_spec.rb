require 'spec_helper.rb'

describe Flattery::Settings do
  subject(:settings) { described_class.new }

  describe ".new" do
    it 'has the expected defaults' do
      expect(subject.klass).to be_nil
      expect(subject.raw_settings).to eql([])
      expect(subject.resolved_settings).to eql({})
      expect(subject.resolved).to eql(false)
    end
    context "when given class parameter" do
      subject(:settings) { described_class.new(klass) }
      let(:klass) { String }
      it 'has the expected defaults' do
        expect(subject.klass).to eql(klass)
      end
    end
  end

  def add_dummy_settings_values
    settings.raw_settings = [1, 2, 3, 4]
    settings.resolved_settings = {a: :b}
    settings.resolved = true
    settings
  end

  describe ".reset!" do
    subject { settings.reset! }
    it 'reverts all settings to defaults' do
      add_dummy_settings_values
      expect { subject }.to change { settings.raw_settings }.from([1, 2, 3, 4]).to([])
      expect(settings.resolved_settings).to eql({})
      expect(settings.resolved).to eql(false)
    end
  end

  describe ".add_setting" do
    subject { settings.add_setting(new_setting) }
    context "when given empty hash" do
      let(:new_setting) { {} }
      it "does nothing" do
        add_dummy_settings_values
        expect { subject }.to_not change { settings.raw_settings }.from([1,2,3,4])
      end
    end

    context "when given nil" do
      let(:new_setting) {}
      it "should cause a reset!" do
        expect(settings).to receive(:reset!)
        subject
      end
    end

    context "when given options as Symbols" do
      let(:new_setting) { { category: :name } }
      it 'records the setting' do
        expect { subject }.to change { settings.raw_settings }.to([
          { from_entity: :category, to_entity: :name, as: nil }
        ])
      end

      context "and then given another definition" do
        let(:another_setting) { { person: :email } }
        subject do
          settings.add_setting(new_setting)
          settings.add_setting(another_setting)
        end
        it 'records add settings' do
          expect { subject }.to change { settings.raw_settings }.to([
            { from_entity: :category, to_entity: :name, as: nil },
            { from_entity: :person, to_entity: :email, as: nil }
          ])
        end
        context "and then reset with nil" do
          subject do
            settings.add_setting new_setting
            settings.add_setting another_setting
            settings.add_setting nil
          end
          it 'clears all settings' do
            expect { subject }.to change { settings.raw_settings }.to([])
          end
        end
      end
    end

    context "when optional :as specified as Symbols" do
      let(:new_setting) { { category: :name, as: :cat_name } }
      it 'records the setting' do
        expect { subject }.to change { settings.raw_settings }.to([
          { from_entity: :category, to_entity: :name, as: 'cat_name' }
        ])
      end
    end

    context "when optional :method specified as Symbols" do
      let(:new_setting) { { category: :name, method: :my_custom_updater } }
      it 'records the setting' do
        expect { subject }.to change { settings.raw_settings }.to([
          { from_entity: :category, to_entity: :name, as: nil, method: :my_custom_updater }
        ])
      end
    end

    context "when optional :background_with specified as Symbols" do
      let(:new_setting) { { category: :name, background_with: :delayed_job } }
      it 'records the setting' do
        expect { subject }.to change { settings.raw_settings }.to([
          { from_entity: :category, to_entity: :name, as: nil, background_with: :delayed_job }
        ])
      end
    end

    context "when given options as String" do
      let(:new_setting) { { 'category' => 'name' } }
      it 'records the setting' do
        expect { subject }.to change { settings.raw_settings }.to([
          { from_entity: :category, to_entity: :name, as: nil }
        ])
      end
    end

    context "when optional :as specified as String" do
      let(:new_setting) { { 'category' => 'name', 'as' => 'cat_name' } }
      it 'records the setting' do
        expect { subject }.to change { settings.raw_settings }.to([
          { from_entity: :category, to_entity: :name, as: 'cat_name' }
        ])
      end
    end

    context "with :batch_size option" do
      context "specified with Symbol keys" do
        let(:new_setting) { { category: :name, batch_size: 10 } }
        it 'records the setting' do
          expect { subject }.to change { settings.raw_settings }.to([
            { from_entity: :category, to_entity: :name, as: nil, batch_size: 10 }
          ])
        end
      end
      context "specified with String keys" do
        let(:new_setting) { { 'category' => 'name', 'batch_size' => 10 } }
        it 'records the setting' do
          expect { subject }.to change { settings.raw_settings }.to([
            { from_entity: :category, to_entity: :name, as: nil, batch_size: 10 }
          ])
        end
      end
      context "not a valid integer" do
        let(:new_setting) { { category: :name, batch_size: 'abc' } }
        it 'records the setting' do
          expect { subject }.to change { settings.raw_settings }.to([
            { from_entity: :category, to_entity: :name, as: nil, batch_size: 0 }
          ])
        end
      end
    end
  end

  describe "#settings" do
    subject { settings.settings }
    context "when initially not resolved" do
      it "invokes resolve_settings!" do
        expect(settings).to receive(:resolve_settings!)
        subject
      end
      it "marks as resolved" do
        expect { subject}.to change { settings.resolved }.from(false).to(true)
      end
    end
    context "when initially resolved" do
      before { add_dummy_settings_values }
      it "never invokes resolve_settings!" do
        expect(settings).to_not receive(:resolve_settings!)
        subject
      end
      it "does not change resolved status" do
        expect { subject }.to_not change { settings.resolved }.from(true)
      end
    end
  end
end
