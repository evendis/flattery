class Flattery::ValueCache::Processor
  # Command: updates cached values for related changed attributes
  def before_save(record)
    resolved_options!(record.class).each do |key,options|
      if record.changed & options[:changed_on]
        record.send("#{key}=", record.send(options[:from_entity]).try(:send, options[:to_entity]))
      end
    end
    true
  end

  # Command: resolves value cache options for +klass+ if required, and returns resolved options
  def resolved_options!(klass)
    klass.value_cache_options.settings
  end
end
