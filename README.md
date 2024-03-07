# rails-pattern_matching

[![Build Status](https://github.com/kddnewton/rails-pattern_matching/workflows/Main/badge.svg)](https://github.com/kddnewton/rails-pattern_matching/actions)
[![Gem](https://img.shields.io/gem/v/rails-pattern_matching.svg)](https://rubygems.org/gems/rails-pattern_matching)

This gem provides the pattern matching interface for `ActionController::Parameters`, `ActiveModel::AttributeMethods`, `ActiveRecord::Base`, and `ActiveRecord::Relation`.

That means it allows you to write code using pattern matching within your Rails applications like the following examples:

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  has_many :comments
end

# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def update
    @post = Post.find(params[:id])

    case params.require(:post).permit(:title, :body, :published)
    in { published: true } if !can_publish?(@post, current_user)
      # Here we are matching against a single parameter with a guard clause.
      # This allows us to express both the value check and the authorization
      # check in a single line.
      render :edit, alert: "You are not authorized to publish this post"
    in permitted if @post.update(permitted)
      # Here we are grabbing the entire set of parameters and then using it to
      # update the post. If the update succeeds, this branch will be taken.
      redirect_to @post, notice: "Post was successfully updated"
    else
      # Here we are providing a default in case none of the above match. This
      # will be taken if the update fails, and presumably the view will render
      # appropriate error messages.
      render :edit
    end
  end
end

# app/helpers/posts_helper.rb
module PostsHelper
  def comment_header_for(post)
    case post
    in { comments: [] }
      # Here we're matching against an attribute on the post that is an
      # association. It will go through the association and then match against
      # the records in the relation.
      "No comments yet"
    in { user_id:, comments: [*, { user_id: ^user_id }, *] }
      # Here we're searching for a comment that has the same user_id as the
      # post. We can do this with the "find" pattern. This syntax is all baked
      # into Ruby, so we don't have to do anything other than define the
      # requisite deconstruct methods that are used by the pattern matching.
      "Author replied"
    in { comments: [{ user: { name: } }] }
      # Here we're extracting the first comment out of the comments association
      # and using its associated user's name in the header.
      "One comment from #{name}"
    in { comments: }
      # Here we provide a default in case none of the above match. Since we have
      # already matched against an empty array of comments and a single element
      # array, we know that there are at least two comments. We can get the
      # length of the comments association by capturing the comments association
      # in the pattern itself and then using it.
      "#{comments.length} comments"
    end
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails-pattern_matching"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-pattern_matching

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kddnewton/rails-pattern_matching.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
