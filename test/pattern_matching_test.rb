# frozen_string_literal: true

require "test_helper"

class PatternMatchingTest < Test::Unit::TestCase
  test "model" do
    person = Person.new
    person.name = "Rails"

    assert_equal({ name: "Rails" }, person.deconstruct_keys([:name]))
  end

  test "record" do
    post = Post.new(title: "Rails")

    assert_equal({ title: "Rails" }, post.deconstruct_keys([:title]))
  end

  test "relation" do
    post = Post.create!(title: "Rails")
    comment = post.comments.build(body: "This is a comment on Rails.")

    relation = post.deconstruct_keys([:comments]).fetch(:comments)
    assert_equal [comment], relation.deconstruct
  end
end
