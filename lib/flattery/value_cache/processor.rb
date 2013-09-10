class Flattery::ValueCache::Processor

  # Command: updates cached values for related changed attributes
  def before_save(record)
    resolved_options!(record.class).each do |key,options|
      if record.changed & options[:changed_on]
        record.send("#{key}=", record.send(options[:association_name]).try(:send,options[:association_method]))
      end
    end
    true
  end

  # Command: resolves value cache options for +klass+ if required, and returns resolved options
  def resolved_options!(klass)
    klass.value_cache_options[:resolved] ||= resolve_options(klass)
  end

  # Returns freshly resolved options for +klass+
  def resolve_options(klass)
    Array(klass.value_cache_options[:settings]).each_with_object({}) do |setting,memo|
      association_name = setting[:association_name]
      association_method = setting[:association_method]
      cache_attribute = (setting[:as] || "#{association_name}_#{association_method}").to_s

      assoc = klass.reflect_on_association(association_name)
      cache_options = if assoc && assoc.belongs_to? && assoc.klass.column_names.include?("#{association_method}")
        {
          association_name: association_name,
          association_method: association_method,
          changed_on: [assoc.foreign_key]
        }
      end

      if cache_options
        memo[cache_attribute] = cache_options
      else
        memo.delete(cache_attribute)
      end
    end
  end
  protected :resolve_options

end
