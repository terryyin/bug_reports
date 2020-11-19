require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "rails", github: "rails/rails"
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.datetime :confirmed_at
  end
end

class Post < ActiveRecord::Base
end

class BugTest < Minitest::Test
  def test_persisted_datetime_should_eq_in_memory
    dt = Time.now.utc
    post = Post.create! confirmed_at: dt
    post_dup = Post.find(post.id)

    # This will fail on linux because of the reason in the next test
    assert_equal post.confirmed_at, post_dup.confirmed_at
  end

  def test_datetime_precision_is_default_to_nil_for_sqlite
    column = Post.type_for_attribute('confirmed_at')

    # I'm not sure 0 is a good default (it is 0 for mysql),
    # but being nil cause the above problem
    assert_equal column.precision, 0
  end

  def test_adapter_behavior
    # this is the correct behavior
    precision = ActiveRecord::Base.connection.send(:extract_precision, 'datetime(6)')
    assert_equal precision, 6

    # this is probably fixing point
    precision = ActiveRecord::Base.connection.send(:extract_precision, 'datetime')
    assert_equal precision, 0
  end
end
