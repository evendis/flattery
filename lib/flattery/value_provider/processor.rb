class Flattery::ValueProvider::Processor

  # Command: pushes cache updates for related changed attributes
  def after_update(record)
    resolved_options!(record.class).each do |key,options|
      if record.changed.include?(key)
        if cache_column = options[:as]
          new_value = record.send(key)
          association_name = options[:to_entity]
          case options[:method]
          when :update_all
            record.send(association_name).update_all({cache_column => new_value})
          else # it is a custom update method
            record.send(options[:method],key.to_sym,new_value,association_name,cache_column)
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
    klass.value_provider_options.settings
  end

end
