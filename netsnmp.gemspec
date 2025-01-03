# frozen_string_literal: true

require File.expand_path("lib/netsnmp/version", __dir__)

Gem::Specification.new do |gem|
  gem.name        = "netsnmp"
  gem.version     = NETSNMP::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Tiago Cardoso"]
  gem.email       = "cardoso_tiago@hotmail.com"

  gem.description = <<-DESC
    Wraps the net-snmp core usage into idiomatic ruby.
    It is designed to support as many environments and concurrency frameworks as possible.
  DESC
  gem.summary     = "SNMP Client library"
  gem.homepage    = "https://github.com/HoneyryderChuck/ruby-netsnmp"
  gem.license     = "Apache-2.0"

  gem.metadata = {
    "bug_tracker_uri" => "https://github.com/HoneyryderChuck/ruby-netsnmp/issues",
    "changelog_uri" => "https://github.com/HoneyryderChuck/ruby-netsnmp/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/github/HoneyryderChuck/ruby-netsnmp",
    "source_code_uri" => "https://github.com/HoneyryderChuck/ruby-netsnmp",
    "homepage_uri" => "https://github.com/HoneyryderChuck/ruby-netsnmp",
    "rubygems_mfa_required" => "true"
  }

  # Manifest
  gem.files = Dir["LICENSE.txt", "README.md", "AUTHORS", "lib/**/*.rb", "sig/**/*.rbs"]
  gem.require_paths = ["lib"]

  gem.add_dependency "parslet"
end
