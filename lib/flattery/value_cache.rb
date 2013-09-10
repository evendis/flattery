module Flattery::ValueCache
  extend ActiveSupport::Concern

  included do
    class_attribute :value_cache_options
    self.value_cache_options = {}

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
      if options.nil?
        self.value_cache_options = {}
        return
      end

      self.value_cache_options ||= {}
      return if options.empty?
      self.value_cache_options[:settings] ||= []
      self.value_cache_options[:resolved] = nil # clear resolved settings

      opt = options.symbolize_keys
      association_name = opt.keys.first
      association_method = opt[association_name].try(:to_sym)
      as_setting = opt.delete(:as).try(:to_s)

      cache_options = {
        association_name: association_name,
        association_method: association_method,
        as: as_setting
      }

      self.value_cache_options[:settings] << cache_options
    end


  end

end

require "flattery/value_cache/processor"
