# frozen_string_literal: true

module NETSNMP
  module Loggable
    DEBUG = ENV.key?("NETSNMP_DEBUG") ? $stderr : nil #: IO?
    DEBUG_LEVEL = ENV.fetch("NETSNMP_DEBUG", 1).to_i #: Integer

    # @rbs!
    #   @debug: IO?
    #   @debug_level: Integer

    #: (?debug: IO, ?debug_level: Integer, **untyped) -> void
    def initialize_logger(debug: DEBUG, debug_level: DEBUG_LEVEL, **)
      @debug = debug
      @debug_level = debug_level
    end

    private

    #: (?level: Integer) { () -> String } -> void
    def log(level: @debug_level)
      return unless (debug_stream = @debug)
      return unless @debug_level >= level

      debug_stream << (+"\n" << yield << "\n")
    end
  end
end
