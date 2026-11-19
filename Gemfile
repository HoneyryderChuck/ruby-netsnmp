# frozen_string_literal: true

source "https://rubygems.org/"
ruby RUBY_VERSION

gemspec

gem "rake"
gem "rspec"

unless ENV.key?("NO_XORCIST")
  platform :mri, :truffleruby do
    gem "xorcist", require: false
  end
end

platform :mri do
  if RUBY_VERSION >= "3.2.0"
    gem "celluloid-io", "~> 0.17"
    gem "rbs"
    gem "rubocop"
    gem "rubocop-performance"
  end
end

if RUBY_VERSION >= "3.2.0"
  group :coverage do
    gem "repo-small-badge", require: false
    gem "simplecov", ">= 1.0.0", require: false
  end
end
