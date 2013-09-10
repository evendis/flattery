module Flattery::ValueProvider
  extend ActiveSupport::Concern

  included do
    class_attribute :value_provider_options
    self.value_provider_options = {}

    before_update Processor.new
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
      if options.nil?
        self.value_provider_options = {}
        return
      end

      self.value_provider_options ||= {}
      return if options.empty?
      self.value_provider_options[:settings] ||= []
      self.value_provider_options[:resolved] = nil # clear resolved settings

      opt = options.symbolize_keys
      as_setting = opt.delete(:as).try(:to_s)

      association_method = opt.keys.first
      association_name = opt[association_method].try(:to_sym)

      cache_options = {
        association_name: association_name,
        association_method: association_method,
        method: :update_all,
        as: as_setting
      }

      self.value_provider_options[:settings] << cache_options
    end

  end

end

require "flattery/value_provider/processor"
