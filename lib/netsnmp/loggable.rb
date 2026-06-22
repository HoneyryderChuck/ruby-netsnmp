# frozen_string_literal: true

module NETSNMP
  module Loggable
    DEBUG = ENV.key?("NETSNMP_DEBUG") ? $stderr : nil
    DEBUG_LEVEL = ENV.fetch("NETSNMP_DEBUG", 1).to_i

    def initialize_logger(debug: DEBUG, debug_level: DEBUG_LEVEL, **)
      @debug = debug
      @debug_level = debug_level
    end

    private

    def log(level: @debug_level)
      return unless @debug
      return unless @debug_level >= level

      debug_stream = @debug

      debug_stream << (+"\n" << yield << "\n")
    end
  end
end
