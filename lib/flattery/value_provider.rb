module Flattery::ValueProvider
  extend ActiveSupport::Concern

  included do
    class_attribute :value_provider_options
    self.value_provider_options = Settings.new(self)
    after_update Processor.new
  end

  module ClassMethods

    # Command: adds flattery definition +options+.
    # The +options+ define a single cache setting. To define multiple cache settings, call over again for each setting.
    #
    # +options+ by example:
    #    push_flattened_values_for :name => :notes
    #    # => will update the cached value of :name in all related Note model instances
    #    push_flattened_values_for :name => :notes, as: 'cat_name'
    #    # => will update the cached value of :name in the 'cat_name' column of all related Note model instances
    #
    # When explicitly passed nil, it clears all existing settings
    #
    def push_flattened_values_for(options={})
      self.value_provider_options.add_setting(options)
    end

  end

end

require "flattery/value_provider/settings"
require "flattery/value_provider/processor"
