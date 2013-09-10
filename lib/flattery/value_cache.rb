module Flattery::ValueCache
  extend ActiveSupport::Concern

  included do
    class_attribute :value_cache_options
    self.value_cache_options = Settings.new(self)
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

  end

end

require "flattery/value_cache/settings"
require "flattery/value_cache/processor"
