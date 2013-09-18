class Flattery::Settings

  attr_accessor :klass
  attr_accessor :raw_settings
  attr_accessor :resolved_settings
  attr_accessor :resolved

  def initialize(klass=nil)
    self.klass = klass
    reset!
  end

  def add_setting(options={})
    if options.nil?
      reset!
      return
    end
    return if options.empty?
    unresolved!
    self.raw_settings << parse_option_setting(options)
  end

  # Process +options+ and return a standardised raw_setting hash
  def parse_option_setting(options)
    cache_options = setting_template

    opt = options.symbolize_keys
    as_setting = opt.delete(:as).try(:to_s)
    method_setting = opt.delete(:method).try(:to_sym)
    background_setting = opt.delete(:background_with).try(:to_sym)
    batch_size_setting = opt.delete(:batch_size).try(:to_i)

    if from_entity = opt.keys.first
      cache_options[:from_entity] = from_entity
      cache_options[:to_entity] = opt[from_entity].try(:to_sym)
    end
    cache_options[:as] = as_setting
    cache_options[:method] = method_setting if method_setting
    cache_options[:background_with] = background_setting if background_setting
    cache_options[:batch_size] = batch_size_setting if batch_size_setting

    cache_options
  end

  # Returns the basic settings template
  def setting_template
    {}
  end

  # Command: mark settings as unresolved
  def unresolved!
    self.resolved = false
  end

  # Command: clear/reset all settings
  def reset!
    self.raw_settings = []
    self.resolved_settings = {}
    self.resolved = false
  end

  # Returns resolved settings
  def settings
    unless resolved
      self.resolved = resolve_settings!
    end
    self.resolved_settings
  end

  # Command: sets resolved_settings. Returns true if resolution was success (which will set the resolution status)
  def resolve_settings!
    true
  end

end
