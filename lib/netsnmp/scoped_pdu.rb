# frozen_string_literal: true

module NETSNMP
  class ScopedPDU < PDU
    using ASNExtensions

    # @rbs @context: String?

    attr_reader :engine_id #: String?

    attr_reader :security_level #: Integer

    attr_reader :auth_param #: String

    # @rbs type: Integer
    # @rbs auth_param: String
    # @rbs security_level: Integer
    # @rbs engine_id: String
    # @rbs context: String
    def initialize(type:, auth_param: "", security_level: 3, engine_id: nil, context: nil, **options)
      @auth_param = auth_param
      @security_level = security_level
      @engine_id = engine_id
      @context = context
      super(type: type, version: 3, community: nil, **options)
    end

    private

    #: -> [OpenSSL::ASN1::OctetString, OpenSSL::ASN1::OctetString]
    def encode_headers_asn
      [
        OpenSSL::ASN1::OctetString.new(@engine_id || "").with_label(:engine_id),
        OpenSSL::ASN1::OctetString.new(@context || "").with_label(:context)
      ]
    end
  end
end
