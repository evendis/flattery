class Flattery::ValueProvider::Processor

  # Command: pushes cache updates for related changed attributes
  def before_update(record)
    record.class.value_provider_options.each do |key,options|
      if record.changed.include?(key)

        association_name = options[:association_name]

        cache_column = if options[:cached_attribute_name] == :inflect
          name = nil
          if assoc = record.class.reflect_on_association(association_name)
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
            new_value = record.send(key)
            record.send(association_name).update_all({cache_column => new_value})
          end
        else
          raise Flattery::CacheColumnInflectionError.new("#{record.class.name} #{key}: #{options}")
        end
      end
    end
    true
  end

end
