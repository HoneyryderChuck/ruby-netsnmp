# frozen_string_literal: true

source "https://rubygems.org/"
ruby RUBY_VERSION

gemspec

gem "minitest"
gem "minitest-hooks"
gem "rake"

unless ENV.key?("NO_XORCIST")
  platform :mri, :truffleruby do
    gem "xorcist", require: false
  end
end

platform :mri do
  if RUBY_VERSION >= "3.2.0"
    gem "celluloid-io", "~> 0.17"
    gem "rubocop"
    gem "rubocop-performance"

    group :types do
      gem "rbs"
      gem "rbs-inline", require: false
      gem "steep", require: false
    end
  end
end

if RUBY_VERSION >= "3.2.0"
  group :coverage do
    gem "repo-small-badge", require: false
    gem "simplecov", ">= 1.0.0", require: false
  end
end
