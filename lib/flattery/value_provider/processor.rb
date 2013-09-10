class Flattery::ValueProvider::Processor

  # Command: pushes cache updates for related changed attributes
  def before_update(record)
    resolved_options!(record.class).each do |key,options|
      if record.changed.include?(key)
        if cache_column = options[:as]
          case options[:method]
          when :update_all
            new_value = record.send(key)
            record.send(options[:association_name]).update_all({cache_column => new_value})
          end
        else
          raise Flattery::CacheColumnInflectionError.new("#{record.class.name} #{key}: #{options}")
        end
      end
    end
    true
  end

  # Command: resolves value provider options for +klass+ if required, and returns resolved options
  def resolved_options!(klass)
    klass.value_provider_options[:resolved] ||= resolve_options(klass)
  end

  def resolve_options(klass)
    Array(klass.value_provider_options[:settings]).each_with_object({}) do |setting,memo|
      association_name = setting[:association_name]
      association_method = setting[:association_method]
      push_method = setting[:method]
      attribute_name = "#{association_method}"

      assoc = klass.reflect_on_association(association_name)
      cache_options = if assoc && assoc.macro == :has_many

        cached_attribute_name = if setting[:as].present?
          setting[:as].to_sym
        else
          name = nil
          other_assoc_name = if assoc.inverse_of
            assoc.inverse_of.name
          else
          end
          if other_assoc_name
            name = cache_attribute_for_association(assoc.klass,other_assoc_name,attribute_name)
            name ||= "#{other_assoc_name}_#{attribute_name}"
          end
          name = nil unless name && assoc.klass.column_names.include?(name)
          name
        end

        {
          association_name: association_name,
          as: cached_attribute_name,
          method: push_method
        }
      end

      if cache_options
        memo[attribute_name] = cache_options
      else
        memo.delete(attribute_name)
      end

    end
  end
  protected :resolve_options

  # Returns the cache_column name given +association_name+ and +association_method+
  def cache_attribute_for_association(klass,association_name,association_method)
    if klass.respond_to?(:value_cache_options)
      klass.value_cache_options[:resolved].detect{|k,v| v[:association_name] == association_name.to_sym &&  v[:association_method] ==  association_method.to_sym }.first
    end
  end
  protected :resolve_options

end

__END__
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