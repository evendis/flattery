module Flattery::ValueCache
  extend ActiveSupport::Concern

  included do
    class_attribute :value_cache_options
    self.value_cache_options = {}

    before_save :resolve_value_cache
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
      opt = options.symbolize_keys
      as_setting = opt.delete(:as)
      association_name = opt.keys.first
      association_method = opt[association_name].try(:to_sym)
      cache_attribute = (as_setting || "#{association_name}_#{association_method}").to_s

      assoc = reflect_on_association(association_name)
      cache_options = if assoc && assoc.belongs_to? && assoc.klass.column_names.include?("#{association_method}")
        {
          association_name: association_name,
          association_method: association_method,
          changed_on: [assoc.foreign_key]
        }
      end

      if cache_options
        self.value_cache_options[cache_attribute] = cache_options
      else
        self.value_cache_options.delete(cache_attribute)
      end
    end

    # Returns the cache_column name given +association_name+ and +association_method+
    def cache_attribute_for_association(association_name,association_method)
      value_cache_options.detect{|k,v| v[:association_name] == association_name.to_sym &&  v[:association_method] ==  association_method.to_sym }.first
    end

  end

  # Command: updates cached values for related changed attributes
  def resolve_value_cache
    self.class.value_cache_options.each do |key,options|
      if changed & options[:changed_on]
        self.send("#{key}=", self.send(options[:association_name]).try(:send,options[:association_method]))
      end
    end
    true
  end

end
