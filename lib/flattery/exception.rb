module Flattery
  # A general exception
  class Error < StandardError; end

  # Raised when cannot successfully infer the cache column name
  class CacheColumnInflectionError < Error; end

  # Raised when cannot successfully iget a valid association
  class InvalidAssociationError < Error; end
end
