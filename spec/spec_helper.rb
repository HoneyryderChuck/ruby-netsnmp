# frozen_string_literal: true

GC.auto_compact = true if GC.respond_to?(:auto_compact=)

if ENV.key?("CI") && RUBY_VERSION >= "3.2.0"
  require "simplecov"
  SimpleCov.start do
    merging true
    finalize_merge false
  end
end

require "bundler/setup"
Bundler.require(:default, :test)

if RUBY_VERSION >= "3.4.0"
  Warning.categories.each do |cat|
    Warning[cat] = true
  end
end

gem "minitest"
require "minitest/hooks"
require "minitest/autorun"

if ENV.key?("PARALLEL")
  require "minitest/hell"
  class Minitest::Test
    parallelize_me!
  end
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "netsnmp"

SNMPPORT = ENV.fetch("SNMP_PORT", 1161).to_i
SNMPHOST = ENV.fetch("SNMP_HOST", "localhost")
