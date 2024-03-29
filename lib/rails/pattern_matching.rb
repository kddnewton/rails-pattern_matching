# frozen_string_literal: true

require "active_model"
require "active_record"
require "action_controller"
require "rails/pattern_matching/version"

module Rails
  module PatternMatching
    # This error is raised when the pattern matching behavior is already
    # defined in a class or module that we're trying to extend. We want to be
    # careful not to silently override the behavior that's already there.
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

class ActionController::Parameters
  if method_defined?(:deconstruct_keys)
    raise Rails::PatternMatching::Error, "ActionController::Parameters"
  end

  # Returns a hash of parameters for the given keys. Provides the pattern
  # matching interface for matching against hash patterns. For example:
  #
  #     class PostsController < ApplicationController
  #       before_action :find_post
  #
  #       # PATCH /posts/:id
  #       def update
  #         case post_params
  #         in { published: true, ** } if !can_publish?(current_user)
  #           render :edit, alert: "You are not authorized to publish posts"
  #         in permitted if @post.update(permitted)
  #           redirect_to @post, notice: "Post was successfully updated"
  #         else
  #           render :edit
  #         end
  #       end
  #
  #       private
  #
  #       def find_post
  #         @post = Post.find(params[:id])
  #       end
  #
  #       def post_params
  #         params.require(:post).permit(:title, :body, :published)
  #       end
  #     end
  #
  # Note that for security reasons, this method will only deconstruct keys that
  # have been explicitly permitted. This is to avoid the potential accidental
  # misuse of the `**` operator.
  #
  # Note: as an optimization, Hash#deconstruct_keys (and therefore
  # ActiveSupport::HashWithIndifferentAccess#deconstruct_keys) always returns
  # itself. This works because the return value then has #[] called on it, so
  # everything works out. This can yield some somewhat surprising (albeit
  # correct) results if you call this method manually.
  def deconstruct_keys(keys)
    if permitted?
      to_h.deconstruct_keys(keys)
    else
      raise ArgumentError, "Only permitted parameters can be deconstructed."
    end
  end
end
