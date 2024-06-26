# frozen_string_literal: true

require "forwardable"
module NETSNMP
  # Abstracts the PDU base structure into a ruby object. It gives access to its varbinds.
  #
  class PDU
    using ASNExtensions

    MAXREQUESTID = 0x7fffffff

    using ASNExtensions
    class << self
      def decode(der, **args)
        der = OpenSSL::ASN1.decode(der) if der.is_a?(String)

        *headers, request = der.value

        version, community = headers.map(&:value)

        type = request.tag

        *request_headers, varbinds = request.value

        request_id, error_status, error_index = request_headers.map { |x| x.value.to_i }

        varbs = varbinds.value.map do |varbind|
          oid_asn, val_asn = varbind.value
          oid = oid_asn.value
          { oid: oid, value: val_asn }
        end

        new(type: type,
            version: version.to_i,
            community: community,
            error_status: error_status.to_i,
            error_index: error_index.to_i,
            request_id: request_id.to_i,
            varbinds: varbs,
            **args)
      end

      # factory method that abstracts initialization of the pdu types that the library supports.
      #
      # @param [Symbol] type the type of pdu structure to build
      #
      def build(type, **args)
        typ = case type
              when :get       then 0
              when :getnext   then 1
              #          when :getbulk   then 5
              when :set       then 3
              when :inform    then 6
              when :trap      then 7
              when :response  then 2
              when :report    then 8
              else raise Error, "#{type} is not supported as type"
              end
        new(type: typ, **args)
      end
    end

    attr_reader :varbinds, :type, :version, :community, :request_id

    def initialize(type:,
                   version:,
                   community:,
                   request_id: SecureRandom.random_number(MAXREQUESTID),
                   error_status: 0,
                   error_index: 0,
                   varbinds: [])
      @version = version.to_i
      @community = community
      @error_status = error_status
      @error_index = error_index
      @type = type
      @varbinds = []
      varbinds.each do |varbind|
        add_varbind(**varbind)
      end
      @request_id = request_id
      check_error_status(@error_status)
    end

    def to_der
      to_asn.to_der
    end

    def to_hex
      to_asn.to_hex
    end

    # Adds a request varbind to the pdu
    #
    # @param [OID] oid a valid oid
    # @param [Hash] options additional request varbind options
    # @option options [Object] :value the value for the oid
    def add_varbind(oid:, **options)
      @varbinds << Varbind.new(oid, **options)
    end
    alias << add_varbind

    def to_asn
      request_id_asn = OpenSSL::ASN1::Integer.new(@request_id).with_label(:request_id)
      error_asn = OpenSSL::ASN1::Integer.new(@error_status).with_label(:error)
      error_index_asn = OpenSSL::ASN1::Integer.new(@error_index).with_label(:error_index)

      varbind_asns = OpenSSL::ASN1::Sequence.new(@varbinds.map(&:to_asn)).with_label(:varbinds)

      request_asn = OpenSSL::ASN1::ASN1Data.new([request_id_asn,
                                                 error_asn, error_index_asn,
                                                 varbind_asns], @type,
                                                :CONTEXT_SPECIFIC).with_label(:request)

      OpenSSL::ASN1::Sequence.new([*encode_headers_asn, request_asn]).with_label(:pdu)
    end

    private

    def encode_headers_asn
      [
        OpenSSL::ASN1::Integer.new(@version).with_label(:snmp_version),
        OpenSSL::ASN1::OctetString.new(@community).with_label(:community)
      ]
    end

    # http://www.tcpipguide.com/free/t_SNMPVersion2SNMPv2MessageFormats-5.htm#Table_219
    def check_error_status(status)
      return if status.zero?

      message = case status
                when 1 then "Response-PDU too big"
                when 2 then "No such name"
                when 3 then "Bad value"
                when 4 then "Read Only"
                when 5 then "General Error"
                when 6 then "Access denied"
                when 7 then "Wrong type"
                when 8 then "Wrong length"
                when 9 then "Wrong encoding"
                when 10 then "Wrong value"
                when 11 then "No creation"
                when 12 then "Inconsistent value"
                when 13 then "Resource unavailable"
                when 14 then "Commit failed"
                when 15 then "Undo Failed"
                when 16 then "Authorization Error"
                when 17 then "Not Writable"
                when 18 then "Inconsistent Name"
                else
                  "Unknown Error: (#{status})"
                end
      raise Error, message
    end
  end
end
