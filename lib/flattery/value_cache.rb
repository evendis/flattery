module Flattery::ValueCache
  extend ActiveSupport::Concern

  included do
    before_save Processor.new
  end

  module ClassMethods
    # Command: adds flattery definition +options+.
    # The +options+ define a single cache setting. To define multiple cache settings, call flatten_value once for each setting.
    #
    # +options+ by example:
    #    flatten_value :category => :name
    #    # => will cache self.category.name to self.category_name
    #    flatten_value :category => :name, :as => 'cat_name'
    #    # => will cache self.category.name to self.cat_name
    #
    # When explicitly passed nil, it clears all existing settings
    #
    def flatten_value(options={})
      self.value_cache_options.add_setting(options)
    end

    # Returns the Flattery::ValueCache options value object.
    # It will inherit settings from a parent class if a model hierarchy has been defined
    def value_cache_options
      @value_cache_options ||= if superclass.respond_to?(:value_cache_options)
        my_settings = Settings.new(self)
        my_settings.raw_settings = superclass.value_cache_options.raw_settings.dup
        my_settings
      else
        Settings.new(self)
      end
    end
  end
end

require "flattery/value_cache/settings"
require "flattery/value_cache/processor"
