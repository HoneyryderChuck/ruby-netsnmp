# frozen_string_literal: true

module NETSNMP
  # Abstraction for the v3 semantics.
  class V3Session < Session
    # @rbs!
    #   @context: String
    #   @security_parameters: SecurityParameters
    #   @message_serializer: Message
    #   @engine_boots: Integer
    #   @engine_time: Integer

    # @param [String, Integer] version SNMP version (always 3)
    #: (?context: String, **untyped) -> untyped
    def initialize(context: "", **opts)
      @context = context
      @security_parameters = opts.delete(:security_parameters)
      super
      @message_serializer = Message.new(**opts)
      @engine_boots, @engine_time = nil
    end

    # @see {NETSNMP::Session#build_pdu}
    #
    # @return [NETSNMP::ScopedPDU] a pdu
    #
    #: (pdu_type, *untyped) -> ScopedPDU
    def build_pdu(type, *vars)
      engine_id = security_parameters.engine_id
      ScopedPDU.build(type, engine_id: engine_id, context: @context, varbinds: vars)
    end

    # @see {NETSNMP::Session#send}
    #: (ScopedPDU pdu) -> (PDU | [PDU, String, Integer, Integer])
    def send(pdu)
      log { "sending request..." }
      encoded_request = encode(pdu)
      encoded_response = @transport.send(encoded_request)
      response_pdu, * = decode(encoded_response)
      response_pdu
    end

    private

    #: (**untyped) -> void
    def validate(**options)
      super
      if (s = @security_parameters)
        # inspect public API
        unless s.respond_to?(:encode) &&
               s.respond_to?(:decode) &&
               s.respond_to?(:sign)   &&
               s.respond_to?(:verify)
          raise Error, "#{s} doesn't respect the sec params public API (#encode, #decode, #sign)"
        end
      else
        @security_parameters = SecurityParameters.new(security_level: options[:security_level],
                                                      username: options[:username],
                                                      auth_protocol: options[:auth_protocol],
                                                      priv_protocol: options[:priv_protocol],
                                                      auth_password: options[:auth_password],
                                                      priv_password: options[:priv_password])

      end
    end

    #: -> SecurityParameters
    def security_parameters
      @security_parameters.engine_id = probe_for_engine if @security_parameters.must_revalidate?
      @security_parameters
    end

    # sends a probe snmp v3 request, to get the additional info with which to handle the security aspect
    #
    #: -> String
    def probe_for_engine
      report_sec_params = SecurityParameters.new(security_level: 0,
                                                 username: @security_parameters.username)
      pdu = ScopedPDU.build(:get)
      log { "sending probe..." }
      encoded_report_pdu = @message_serializer.encode(pdu, security_parameters: report_sec_params)

      encoded_response_pdu = @transport.send(encoded_report_pdu)

      _, engine_id, @engine_boots, @engine_time = decode(encoded_response_pdu, security_parameters: report_sec_params)
      engine_id
    end

    #: (ScopedPDU) -> String
    def encode(pdu)
      @message_serializer.encode(pdu, security_parameters: @security_parameters,
                                      engine_boots: @engine_boots,
                                      engine_time: @engine_time)
    end

    #: (String, ?security_parameters: SecurityParameters) -> [PDU, String, Integer, Integer]
    def decode(stream, security_parameters: @security_parameters)
      return_pdu = @message_serializer.decode(stream, security_parameters: security_parameters)

      pdu, *args = return_pdu

      # usmStats: http://oidref.com/1.3.6.1.6.3.15.1.1
      if pdu.type == 8
        case pdu.varbinds.first.oid
        when "1.3.6.1.6.3.15.1.1.1.0" # usmStatsUnsupportedSecLevels
          raise Error, "Unsupported security level"
        when "1.3.6.1.6.3.15.1.1.2.0" # usmStatsNotInTimeWindows
          _, @engine_boots, @engine_time = args
          raise IdNotInTimeWindowError, "Not in time window"
        when "1.3.6.1.6.3.15.1.1.3.0" # usmStatsUnknownUserNames
          raise Error, "Unknown user name"
        when "1.3.6.1.6.3.15.1.1.4.0" # usmStatsUnknownEngineIDs
          raise UnknownEngineIdError, "Unknown engine ID" unless @security_parameters.must_revalidate?
        when "1.3.6.1.6.3.15.1.1.5.0" # usmStatsWrongDigests
          raise Error, "Authentication failure (incorrect password, community or key)"
        when "1.3.6.1.6.3.15.1.1.6.0" # usmStatsDecryptionErrors
          raise Error, "Decryption error"
        end
      end

      # validate_authentication
      @message_serializer.verify(stream, pdu.auth_param, pdu.security_level, security_parameters: @security_parameters)

      return_pdu
    end
  end
end
