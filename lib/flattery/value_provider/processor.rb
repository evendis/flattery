class Flattery::ValueProvider::Processor

  # Command: pushes cache updates for related changed attributes
  def before_update(record)
    resolved_options!(record.class).each do |key,options|
      if record.changed.include?(key)
        if cache_column = options[:as]
          case options[:method]
          when :update_all
            new_value = record.send(key)
            record.send(options[:to_entity]).update_all({cache_column => new_value})
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
