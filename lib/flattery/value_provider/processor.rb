class Flattery::ValueProvider::Processor

  # Command: pushes cache updates for related changed attributes
  def after_update(record)
    resolved_options!(record.class).each do |key,options|
      if record.changed.include?(key)
        if target_attribute = options[:as]
          method = options[:method]
          attribute = key.to_sym
          new_value = record.send(key)
          association_name = options[:to_entity]
          if options[:background_with] == :delayed_job && self.respond_to?(:delay)
            self.delay.apply_push(record,method,attribute,new_value,association_name,target_attribute)
          else
            apply_push(record,method,attribute,new_value,association_name,target_attribute)
          end
        else
          raise Flattery::CacheColumnInflectionError.new("#{record.class.name} #{key}: #{options}")
        end
      end
    end
    true
  end

  # Command: performs an update for a specific cache setting
  def apply_push(record,method,attribute,new_value,association_name,target_attribute)
    case method
    when :update_all
      record.send(association_name).update_all({target_attribute => new_value})
    else # it is a custom update method
      record.send(method,attribute,new_value,association_name,target_attribute)
    end
  end

  # Command: resolves value provider options for +klass+ if required, and returns resolved options
  def resolved_options!(klass)
    klass.value_provider_options.settings
  end

end
