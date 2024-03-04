# frozen_string_literal: true

require "test_helper"

class PatternMatchingTest < Test::Unit::TestCase
  test "model" do
    person = Person.new
    person.name = "Rails"

    assert_equal({ name: "Rails" }, person.deconstruct_keys([:name]))
  end

  test "model **" do
    person = Person.new
    person.name = "Rails"

    assert_equal({ name: "Rails" }, person.deconstruct_keys(nil))
  end

  test "record" do
    post = Post.new(title: "Rails")

    assert_equal({ title: "Rails" }, post.deconstruct_keys([:title]))
  end

  test "record **" do
    post = Post.create!(title: "Rails")
    comment = post.comments.build(body: "This is a comment on Rails.")

    assert_equal(
      { id: 1, title: "Rails", comments: [comment] },
      post.deconstruct_keys(nil)
    )
  end

  test "relation" do
    post = Post.create!(title: "Rails")
    comment = post.comments.build(body: "This is a comment on Rails.")

    relation = post.deconstruct_keys([:comments]).fetch(:comments)
    assert_equal [comment], relation.deconstruct
  end

  test "params unpermitted" do
    params = build_params({})

    assert_raises(ArgumentError) { params.deconstruct_keys(%i[foo]) }
    assert_raises(ArgumentError) { params.deconstruct_keys(nil) }
  end

  test "params" do
    params = build_params({ "foo" => 1, "bar" => 2, "baz" => 3 })
    params = params.permit(:foo, :bar)

    assert_equal(1, params.deconstruct_keys(%i[foo])[:foo])
  end

  test "params **" do
    params = build_params({ "foo" => 1, "bar" => 2, "baz" => 3 })
    params = params.permit(:foo, :bar)

    assert_equal({ "foo" => 1, "bar" => 2 }, params.deconstruct_keys(nil))
  end

  test "params nested" do
    params = build_params({ "foo" => { "bar" => 1, "baz" => 2, "qux" => 3 } })
    params = params.require(:foo).permit(:bar, :baz)

    assert_equal(1, params.deconstruct_keys(%i[bar])[:bar])
    assert_equal({ "bar" => 1, "baz" => 2 }, params.deconstruct_keys(nil))
  end

  private

  def build_params(params)
    ActionController::Parameters.new(params)
  end
end
