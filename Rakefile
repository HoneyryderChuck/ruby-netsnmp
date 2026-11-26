# frozen_string_literal: true

require "bundler/gem_tasks"

begin
  require "minitest/test_task"

  desc "runs the tests"
  Minitest::TestTask.create(:spec) do |t|
    t.libs << "spec"
    t.warning = false
    t.test_globs = ["spec/**/*_spec.rb"]
  end
rescue LoadError
end

begin
  require "rubocop/rake_task"

  desc "Run rubocop"
  task :rubocop do
    RuboCop::RakeTask.new
  end
rescue LoadError
end

class BadgeFormatter
  def initialize(output = nil)
    @output = output || $stdout
  end

  def format(result)
    min_thresholds = SimpleCov.minimum_coverage
    covered_percent = result.source_files.covered_percent.round(0)
    color =
      if min_thresholds.any?
        if SimpleCov::CoverageViolations.minimum_overall(result, SimpleCov.minimum_coverage).any?
          "#ff0000"
        else
          "#ffffcc" # green
        end
      else
        "#808080"
      end
    image = RepoSmallBadge::Image.new(
      {
        output_path: SimpleCov.coverage_dir,
        value_color: color
      }
    )
    image.badge("total", "total", "#{covered_percent}%")
  end
end

namespace :coverage do
  desc "Aggregates coverage reports"
  task :report do
    next unless ENV.key?("CI")

    require "simplecov"
    require "repo_small_badge"

    puts Dir["coverage/**/.resultset.json"].inspect
    SimpleCov.collate(Dir["coverage/**/.resultset.json"]) do
      skip ".bundle/"
      skip "vendor/"
      skip "spec/"
      minimum_coverage 87
      formatter SimpleCov::Formatter::MultiFormatter.new(
        [
          SimpleCov::Formatter::HTMLFormatter,
          BadgeFormatter
        ]
      )
    end
  end
end

task default: [:spec]
