# frozen_string_literal: true

require "bundler/setup"
require "rails/pattern_matching"
require "test-unit"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new("/dev/null")

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title
  end

  create_table :comments, force: true do |t|
    t.references :post
    t.string :body
  end
end

class Person
  include ActiveModel::AttributeMethods

  attr_accessor :name
  define_attribute_methods :name

  def attributes
    { "name" => @name }
  end
end

class Post < ActiveRecord::Base
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post
end
