class Flattery::ValueCache::Settings < Flattery::Settings
  # Command: sets resolved_settings. Returns true if resolution was success (which will set the resolution status)
  #
  # Given raw settings: [{ from_entity: :category, to_entity: :name, as: 'cat_name' }]
  # Resolved settings: { 'cat_name' => { from_entity: :category, to_entity: :name, changed_on: ['category_id'] } }
  #
  # In the ValueCache context:
  # * +from_entity+ is the association from which the cache value is obtained
  # * +to_entity+ is the column that the cache value will be stored in
  # * +as+ is the column name on +from_entity+ from which the cache value is to be read
  #
  # Validations/transformations performed:
  # * from_entity is a valid association
  # * cache attribute name derived from :as or inferred from association/attribute names
  # * cache attribute is a valid column
  #
  # If any of these fail, the setting is excluded from the resolved options.
  #
  def resolve_settings!
    self.resolved_settings = raw_settings.each_with_object({}) do |setting,memo|
      from_entity = setting[:from_entity]
      to_entity = setting[:to_entity]
      cache_attribute = (setting[:as] || "#{from_entity}_#{to_entity}").to_s

      assoc = klass.reflect_on_association(from_entity)
      cache_options = if assoc && assoc.belongs_to? && klass.column_names.include?("#{cache_attribute}")
        {
          from_entity: from_entity,
          to_entity: to_entity,
          changed_on: [assoc.foreign_key]
        }
      end

      if cache_options
        memo[cache_attribute] = cache_options
      else
        memo.delete(cache_attribute)
      end
    end
    true
  end
end
