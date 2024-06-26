# frozen_string_literal: true

require "timeout"

module NETSNMP
  # Main Entity, provides the user-facing API to communicate with SNMP Agents
  #
  # Under the hood it creates a "session" (analogous to the net-snmp C session), which will be used
  # to proxy all the communication to the agent. the Client ensures that you only write pure ruby and
  # read pure ruby, not concerning with snmp-speak like PDUs, varbinds and the like.
  #
  #
  class Client
    RETRIES = 5

    # @param [Hash] options the options to needed to enable the SNMP client.
    # @option options [String, Integer, nil] :version the version of the protocol (defaults to 3).
    #    also accepts common known declarations like :v3, "v2c", etc
    # @option options [Integer] :retries number of retries for each failed PDU (after which it raise timeout error. Defaults to {RETRIES} retries)
    # @yield [client] the instantiated client, after which it closes it for use.
    # @example Yielding a clinet
    #    NETSNMP::Client.new(host: "241.232.22.12") do |client|
    #      puts client.get(oid: "1.3.6.1.2.1.1.5.0")
    #    end
    #
    def initialize(version: nil, **options)
      version = case version
                when Integer then version # assume the use know what he's doing
                when /v?1/ then 0
                when /v?2c?/ then 1
                when /v?3/ then 3
                else 3 # rubocop:disable Lint/DuplicateBranch
                end

      @retries = options.fetch(:retries, RETRIES).to_i
      @session ||= version == 3 ? V3Session.new(**options) : Session.new(version: version, **options)
      return unless block_given?

      begin
        yield self
      ensure
        close
      end
    end

    # Closes the inner section
    def close
      @session.close
    end

    # Performs an SNMP GET Request
    #
    # @see {NETSNMP::Varbind#new}
    #
    def get(*oid_opts)
      request = @session.build_pdu(:get, *oid_opts)
      response = handle_retries { @session.send(request) }
      yield response if block_given?
      values = response.varbinds.map(&:value)
      values.size > 1 ? values : values.first
    end

    # Performs an SNMP GETNEXT Request
    #
    # @see {NETSNMP::Varbind#new}
    #
    def get_next(*oid_opts)
      request = @session.build_pdu(:getnext, *oid_opts)
      response = handle_retries { @session.send(request) }
      yield response if block_given?
      values = response.varbinds.map { |v| [v.oid, v.value] }
      values.size > 1 ? values : values.first
    end

    # Perform a SNMP Walk (issues multiple subsequent GENEXT requests within the subtree rooted on an OID)
    #
    # @param [String] oid the root oid from the subtree
    #
    # @return [Enumerator] the enumerator-collection of the oid-value pairs
    #
    def walk(oid:)
      walkoid = OID.build(oid)
      Enumerator.new do |y|
        code = walkoid
        first_response_code = nil
        catch(:walk) do
          loop do
            get_next(oid: code) do |response|
              response.varbinds.each do |varbind|
                code = varbind.oid
                if !OID.parent?(walkoid, code) ||
                   varbind.value.eql?(:endofmibview) ||
                   (code == first_response_code)
                  throw(:walk)
                else
                  y << [code, varbind.value]
                end
                first_response_code ||= code
              end
            end
          end
        end
      end
    end

    # Perform a SNMP GETBULK Request (performs multiple GETNEXT)
    #
    # @param [String] oid the first oid
    # @param [Hash] options the varbind options
    # @option options [Integer] :errstat sets the number of objects expected for the getnext instance
    # @option options [Integer] :errindex number of objects repeating for all the repeating IODs.
    #
    # @return [Enumerator] the enumerator-collection of the oid-value pairs
    #
    # def get_bulk(oid)
    #  request = @session.build_pdu(:getbulk, *oids)
    #  request[:error_status]  = options.delete(:non_repeaters) || 0
    #  request[:error_index] = options.delete(:max_repetitions) || 10
    #  response = @session.send(request)
    #  Enumerator.new do |y|
    #    response.varbinds.each do |varbind|
    #      y << [ varbind.oid, varbind.value ]
    #    end
    #  end
    # end

    # Perform a SNMP SET Request
    #
    # @see {NETSNMP::Varbind#new}
    #
    def set(*oid_opts)
      request = @session.build_pdu(:set, *oid_opts)
      response = handle_retries { @session.send(request) }
      yield response if block_given?
      values = response.varbinds.map(&:value)
      values.size > 1 ? values : values.first
    end

    # Perform a SNMP INFORM Request
    #
    # @see {NETSNMP::Varbind#new}
    #
    def inform(*oid_opts)
      request = @session.build_pdu(:inform, *oid_opts)
      response = handle_retries { @session.send(request) }
      yield response if block_given?
      values = response.varbinds.map(&:value)
      values.size > 1 ? values : values.first
    end

    private

    # Handles timeout errors by reissuing the same pdu until it runs out or retries.
    def handle_retries
      retries = @retries
      begin
        yield
      rescue Timeout::Error, IdNotInTimeWindowError, UnknownEngineIdError => e
        raise e if retries.zero?

        retries -= 1
        retry
      end
    end
  end
end
