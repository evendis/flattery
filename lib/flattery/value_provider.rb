module Flattery::ValueProvider
  extend ActiveSupport::Concern

  included do
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

    # Returns the Flattery::ValueProvider options value object.
    # It will inherit settings from a parent class if a model hierarchy has been defined
    def value_provider_options
      @value_provider_options ||= if superclass.respond_to?(:value_provider_options)
        my_settings = Settings.new(self)
        my_settings.raw_settings = superclass.value_provider_options.raw_settings.dup
        my_settings
      else
        Settings.new(self)
      end
    end
  end
end

require "flattery/value_provider/settings"
require "flattery/value_provider/processor"
