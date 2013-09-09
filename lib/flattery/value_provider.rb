module Flattery::ValueProvider
  extend ActiveSupport::Concern

  included do
    class_attribute :value_provider_options
    self.value_provider_options = {}

    before_update :resolve_value_provision
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
      opt = options.symbolize_keys
      as_setting = opt.delete(:as)

      attribute_key = opt.keys.first
      association_name = opt[attribute_key]
      attribute_name = "#{attribute_key}"

      cached_attribute_name = (as_setting || "inflect").to_sym

      assoc = reflect_on_association(association_name)
      cache_options = if assoc && assoc.macro == :has_many
        {
          association_name: association_name,
          cached_attribute_name: cached_attribute_name,
          method: :update_all
        }
      end

      if cache_options
        self.value_provider_options[attribute_name] = cache_options
      else
        self.value_provider_options.delete(attribute_name)
      end
    end

  end

  # Command: pushes cache updates for related changed attributes
  def resolve_value_provision
    self.class.value_provider_options.each do |key,options|
      if changed.include?(key)

        association_name = options[:association_name]

        cache_column = if options[:cached_attribute_name] == :inflect
          name = nil
          if assoc = self.class.reflect_on_association(association_name)
            other_assoc_name = if assoc.inverse_of
              assoc.inverse_of.name
            else
            end
            if other_assoc_name
              if assoc.klass.respond_to?(:cache_attribute_for_association)
                name = assoc.klass.cache_attribute_for_association(other_assoc_name,key)
              end
              name ||= "#{other_assoc_name}_#{key}"
            end
            name = nil unless name && assoc.klass.column_names.include?(name)
          end
          name
        else
          options[:cached_attribute_name]
        end

        if cache_column
          case options[:method]
          when :update_all
            new_value = self.send(key)
            self.send(association_name).update_all({cache_column => new_value})
          end
        else
          raise Flattery::CacheColumnInflectionError.new("#{self.class.name} #{key}: #{options}")
        end
      end
    end
    true
  end

end
