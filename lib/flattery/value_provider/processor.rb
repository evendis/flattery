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
          batch_size = options[:batch_size]
          if options[:background_with] == :delayed_job && self.respond_to?(:delay)
            self.delay.apply_push(record,method,attribute,new_value,association_name,target_attribute,batch_size)
          else
            apply_push(record,method,attribute,new_value,association_name,target_attribute,batch_size)
          end
        else
          raise Flattery::CacheColumnInflectionError.new("#{record.class.name} #{key}: #{options}")
        end
      end
    end
    true
  end

  # Command: performs an update for a specific cache setting
  def apply_push(record,method,attribute,new_value,association_name,target_attribute,batch_size)
    case method
    when :update_all
      if batch_size > 0
        total_rows_affected = 0
        rows_affected = 0
        begin
          ActiveRecord::Base.connection.transaction do
            rows_affected = record.send(association_name).where("NOT #{target_attribute} = ?",new_value).limit(batch_size).update_all(target_attribute => new_value)
            total_rows_affected += rows_affected
          end
        end while rows_affected >= batch_size
        total_rows_affected
      else
        record.send(association_name).update_all({target_attribute => new_value})
      end
    else # it is a custom update method
      record.send(method,attribute,new_value,association_name,target_attribute,batch_size)
    end
  end

  # Command: resolves value provider options for +klass+ if required, and returns resolved options
  def resolved_options!(klass)
    klass.value_provider_options.settings
  end

end
