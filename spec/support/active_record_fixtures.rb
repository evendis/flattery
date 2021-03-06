
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ":memory:")

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do

    create_table(:notes, :force => true) do |t|
      t.string :name;
      t.belongs_to :category;
      t.string :category_name;
      t.string :category_description;
      t.string :cat_name;
      t.belongs_to :country;
      t.string :country_name;
      t.string :person_name;
      t.string :person_email;
      t.string :user_email;
    end

    create_table(:categories, :force => true) do |t|
      t.string :name;
      t.string :description;
    end

    create_table(:countries, :force => true) do |t|
      t.string :name;
    end

    create_table(:people, :force => true) do |t|
      t.string :username;
      t.string :email;
    end

  end
end

# Basic models for testing
class Note < ActiveRecord::Base
  belongs_to :category
  belongs_to :country
  belongs_to :person, primary_key: "username", foreign_key: "person_name"
end

class Category < ActiveRecord::Base
  has_many :notes
end

class Country < ActiveRecord::Base
  has_many :notes
end

class Person < ActiveRecord::Base
  has_many :notes, primary_key: "username", foreign_key: "person_name", inverse_of: :person
end

module ArHelper

  # Clears any configuration
  def truncate_records
    Note.delete_all
    Category.delete_all
    Person.delete_all
  end

  def clear_harness_classes
    Object.send(:remove_const, :ValueProviderHarness) if Object.constants.include?(:ValueProviderHarness)
    Object.send(:remove_const, :ChildValueProviderHarness) if Object.constants.include?(:ChildValueProviderHarness)
    Object.send(:remove_const, :ValueCacheHarness) if Object.constants.include?(:ValueCacheHarness)
    Object.send(:remove_const, :ChildValueCacheHarness) if Object.constants.include?(:ChildValueCacheHarness)
  end

end

RSpec.configure do |conf|
  conf.include ArHelper
end
