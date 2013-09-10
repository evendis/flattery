# Flattery [![Build Status](https://secure.travis-ci.org/evendis/flattery.png?branch=master)](http://travis-ci.org/evendis/flattery)

Sometimes you want to do the non-DRY thing and repeat yourself, by caching values from associated records in a master model.
The two main reasons you might want to do this are probably:
* for performance - to avoid joins in search queries and display
* to save values from association records that are subject to deletion yet still have them available when looking at the master record - if you are using the [https://rubygems.org/gems/paranoid](paranoid) gem for example.

Hence flattery - a gem that provides a simple declarative method for caching and maintaining such values.

Flattery is primarily intended for use with relational ActiveRecord storage, and is only tested with sqlite and PostgreSQL.
If you are using NoSQL, you probably wouldn't design your schema in a way for which flattery adds any value - but if you find a situation where this makes sense, then feel free to fork and add the support .. or lobby for it's inclusion!

## Requirements

* Ruby 1.9 or 2
* Rails 3.x/4.x
* ActiveRecord (only sqlite and PostgreSQL tested. Others _should_ work; raise an issue if you find problems)

## Installation

Add this line to your application's Gemfile:

    gem 'flattery'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flattery

## Usage

### How to cache values from a :belongs_to association

Given a model with a :belongs_to association, you want to store a (copy/cached) value from the associated record. The <tt>Flattery::ValueCache</tt> module is used to define the behaviour.

    class Category < ActiveRecord::Base
      has_many :notes, :inverse_of => :category
    end

    class Note < ActiveRecord::Base
      belongs_to :category, :inverse_of => :notes

      include Flattery::ValueCache
      flatten_value :category => :name
    end

In this case, when you save an instance of Note, it will store the instance.category.name value as instance.category_name.
The <tt>:category_name</tt> attribute is inferred from the relationship, and is assumed to be present in the schema.
So before you can use this, you must add a migration to add the <tt>:category_name</tt> column to the notes table (with the same type as the <tt>:name</tt> column on the Category table).


### How to cache the value in a specific column name

In the usual case, the cache column name is inferred from the association (e.g. <tt>:category_name</tt> in the example above).
If you want to store in another column name, use the <tt>:as</tt> option on the <tt>flatten_value</tt> call:

    class Note < ActiveRecord::Base
      belongs_to :category

      include Flattery::ValueCache
      flatten_value :category => :name, :as => 'cat_name'
    end

Again, you must make sure the column is correctly defined in your schema.

### How to push updates to cached values from the source model

Given the example above, we have a problem if Category records are updated - the <tt>:category_name</tt> value stored in Notes gets out of sync. The <tt>Flattery::ValueProvider</tt> module fixes this by propagating changes accordingly.

    class Category < ActiveRecord::Base
      has_many :notes

      include Flattery::ValueProvider
      push_flattened_values_for :name => :notes
    end

This will push changes to Category <tt>:name</tt> to Notes records (by inference, updating the <tt>:category_name</tt> value in Notes).

### How to push updates to cached values from the source model to a specific cache column name

If the cache column name cannot be inferred correctly, an error will be raised. Inference errors can occur if the inverse association relation cannot be determined.

To help flattery figure out the correct column name, specify the column name with an <tt>:as</tt> option:

    class Category < ActiveRecord::Base
      has_many :notes

      include Flattery::ValueProvider
      push_flattened_values_for :name => :notes, :as => 'cat_name'
    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
