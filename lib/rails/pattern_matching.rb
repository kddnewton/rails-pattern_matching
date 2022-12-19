# frozen_string_literal: true

require "active_model"
require "active_record"
require "rails/pattern_matching/version"

module Rails
  module PatternMatching
    class Error < StandardError
      def initialize(context)
        super(<<~MSG)
          Pattern matching appears to already be defined in #{context}. In this
          case the rails-pattern_matching gem should not be used because it
          would override the pattern matching behavior given by #{context}.
        MSG
      end
    end
  end
end

class ActiveRecord::Base
  if method_defined?(:deconstruct_keys)
    raise Rails::PatternMatching::Error, "ActiveRecord::Base"
  end

  # Returns a hash of attributes for the given keys. Provides the pattern
  # matching interface for matching against hash patterns. For example:
  #
  #   class Person < ActiveRecord::Base
  #   end
  #
  #   def greeting_for(person)
  #     case person
  #     in { name: "Mary" }
  #       "Welcome back, Mary!"
  #     in { name: }
  #       "Welcome, stranger!"
  #     end
  #   end
  #
  #   person = Person.new
  #   person.name = "Mary"
  #   greeting_for(person) # => "Welcome back, Mary!"
  #
  #   person = Person.new
  #   person.name = "Bob"
  #   greeting_for(person) # => "Welcome, stranger!"
  #
  def deconstruct_keys(keys)
    if keys
      # If we've been given keys, then we're going to filter down to just the
      # values that are being requested.
      keys.each_with_object({}) do |key, deconstructed|
        method = key.to_s

        # We don't need to worry about the case where the user provided a key
        # that doesn't match an attribute or association, because the match
        # will fail by virtue of there not being a key in the result hash.
        if attribute_method?(method)
          # Here we're pattern matching against an attribute method. We're
          # going to use the [] method so that we either get the value or
          # raise an error for a missing attribute in case it wasn't loaded.
          deconstructed[key] = public_send(method)
        elsif self.class.reflect_on_association(method)
          # Here we're going to pattern match against an association. We're
          # going to use the main interface for that association which can
          # be further pattern matched later.
          deconstructed[key] = public_send(method)
        end
      end
    else
      # If we haven't been given keys, then the user wants to grab up all of the
      # attributes and associations for this record.
      attributes.transform_keys(&:to_sym).merge!(
        self.class.reflect_on_all_associations.to_h do |reflection|
          [reflection.name, public_send(reflection.name)]
        end
      )
    end
  end
end

class ActiveRecord::Relation
  if method_defined?(:deconstruct)
    raise Rails::PatternMatching::Error, "ActiveRecord::Relation"
  end

  # Provides the pattern matching interface for matching against array
  # patterns. For example:
  #
  #   class Person < ActiveRecord::Base
  #   end
  #
  #   case Person.all
  #   in []
  #     "No one is here"
  #   in [{ name: "Mary" }]
  #     "Only Mary is here"
  #   in [_]
  #     "Only one person is here"
  #   in [_, _, *]
  #     "More than one person is here"
  #   end
  #
  # Be wary when using this method with a large number of records, as it
  # will load everything into memory.
  #
  def deconstruct
    records
  end
end

module ActiveModel::AttributeMethods
  if method_defined?(:deconstruct_keys)
    raise Rails::PatternMatching::Error, "ActiveModel::AttributeMethods"
  end

  # Returns a hash of attributes for the given keys. Provides the pattern
  # matching interface for matching against hash patterns. For example:
  #
  #   class Person
  #     include ActiveModel::AttributeMethods
  #
  #     attr_accessor :name
  #     define_attribute_method :name
  #   end
  #
  #   def greeting_for(person)
  #     case person
  #     in { name: "Mary" }
  #       "Welcome back, Mary!"
  #     in { name: }
  #       "Welcome, stranger!"
  #     end
  #   end
  #
  #   person = Person.new
  #   person.name = "Mary"
  #   greeting_for(person) # => "Welcome back, Mary!"
  #
  #   person = Person.new
  #   person.name = "Bob"
  #   greeting_for(person) # => "Welcome, stranger!"
  #
  def deconstruct_keys(keys)
    if keys
      # If we've been given keys, then we're going to filter down to just the
      # attributes that were given for this object.
      keys.each_with_object({}) do |key, deconstructed|
        string_key = key.to_s

        # If the user provided a key that doesn't match an attribute, then we
        # do not add it to the result hash, and the match will fail.
        if attribute_method?(string_key)
          deconstructed[key] = public_send(string_key)
        end
      end
    else
      # If we haven't been given keys, then the user wants to grab up all of the
      # attributes for this object.
      attributes.transform_keys(&:to_sym)
    end
  end
end
