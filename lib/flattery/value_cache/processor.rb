class Flattery::ValueCache::Processor

  # Command: updates cached values for related changed attributes
  def before_save(record)
    record.class.value_cache_options.each do |key,options|
      if record.changed & options[:changed_on]
        record.send("#{key}=", record.send(options[:association_name]).try(:send,options[:association_method]))
      end
    end
    true
  end

end
