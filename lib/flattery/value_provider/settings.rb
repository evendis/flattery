class Flattery::ValueProvider::Settings < Flattery::Settings
  # Returns the basic settings template
  def setting_template
    {method: :update_all, batch_size: 0}
  end

  # Command: sets resolved_settings. Returns true if resolution was success (which will set the resolution status)
  #
  # Given raw settings: [{ from_entity: :name, to_entity: :notes, as: 'cat_name', method: :update_all }]
  # Resolved settings: { 'name' => { to_entity: :notes, as: 'cat_name', method: :update_all } }
  #
  # In the ValueProvider context:
  # * +from_entity+ is the column that provides the cache value
  # * +to_entity+ is the association to which the cache value is pushed
  # * +as+ is the column name on +to_entity+ from which the cache value is to be stored
  #
  # Validations/transformations performed:
  # * to_entity is a valid association
  #
  # If any of these fail, the setting is excluded from the resolved options.
  #
  def resolve_settings!
    self.resolved_settings = raw_settings.each_with_object({}) do |setting, memo|
      from_entity = setting[:from_entity]
      to_entity = setting[:to_entity]

      push_method = setting[:method]
      background_with = setting[:background_with]
      batch_size = setting[:batch_size]
      attribute_name = "#{from_entity}"

      assoc = klass.reflect_on_association(to_entity)
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
          to_entity: to_entity,
          as: cached_attribute_name,
          method: push_method,
          background_with: background_with,
          batch_size: batch_size
        }
      end

      if cache_options
        memo[attribute_name] = cache_options
      else
        memo.delete(attribute_name)
      end

    end
    true
  end

  # Returns the cache_column name given +association_name+ and +association_method+
  def cache_attribute_for_association(klass,association_name,association_method)
    if klass.respond_to?(:value_cache_options)
      klass.value_cache_options.settings.detect{|k,v| v[:from_entity] == association_name.to_sym &&  v[:to_entity] ==  association_method.to_sym }.first
    end
  end
end
