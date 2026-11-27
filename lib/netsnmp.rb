# frozen_string_literal: true

require "netsnmp/version"
require "openssl"
require "io/wait"
require "securerandom"
require "ipaddr"

# core structures

module NETSNMP
  # @rbs!
  #  type oid = String | Array[_ToS]
  #
  #  type oid_type = Integer | :ipaddress | :counter32 | :gauge | :timetick | :opaque | :nsap | :counter64 | :uinteger
  #
  #  type oid_value = String | Integer | Timetick | true | false | nil | IPAddr
  #
  #  type pdu_type = :get | :getnext | :set | :inform | :trap | :response
  #
  #  type auth_protocol = :md5 | :sha | :sha1 | :sha224 | :sha256 | :sha384 | :sha512
  #
  #  type priv_protocol = :aes | :aes128 | :aes192 | :aes256 | :des
  #
  #  type varbind_options = {oid: String, value: Varbind::varbind_value }
  #                       | {oid: String, value: Varbind::varbind_value, type: oid_type}
  #
  #  interface _Logger
  #    def <<: (string) -> void
  #  end
  #
  #  interface _Authenticate
  #    def reset: () -> void
  #    def <<: (string) -> void
  #    def digest: () -> String
  #  end
  #
  #  interface _ToAsn
  #    def to_asn: () -> OpenSSL::ASN1::ASN1Data
  #  end
  #
  #  type snmp_version = 0 | 1 | 3 | :v1 | :v2c | :v3 | String | nil

  begin
    require "xorcist"
    require "xorcist/refinements"
    # @rbs skip
    XorExtensions = Xorcist::Refinements
  rescue LoadError
    # "no xorcist"
    module XorExtensions
      refine String do
        # Bitwise XOR operator for the String class
        def xor(other)
          b1 = unpack("C*")
          return b1 unless other

          b2 = other.unpack("C*")
          longest = [b1.length, b2.length].max
          b1 = ([0] * (longest - b1.length)) + b1
          b2 = ([0] * (longest - b2.length)) + b2
          b1.zip(b2).map { |a, b| a ^ b }.pack("C*")
        end
      end
    end
  end

  module Hexdump
    module_function

    #: (String, ?width: Integer, ?in_groups_if: Integer, ?separator: String)
    def dump(data, width: 8, in_groups_of: 4, separator: "\n")
      pairs = data.unpack1("H*").scan(/.{#{in_groups_of}}/)
      pairs.each_slice(width).map do |row|
        row.join(" ")
      end.join(separator)
    end
  end

  # Like a string, but it prints an hex-string version of itself
  class HexString < String
    #: -> String
    def inspect
      Hexdump.dump(to_s, in_groups_of: 2, separator: " ")
    end
  end
  private_constant :Hexdump, :HexString
end

require "netsnmp/errors"
require "netsnmp/extensions"
require "netsnmp/loggable"

require "netsnmp/timeticks"

require "netsnmp/oid"
require "netsnmp/varbind"
require "netsnmp/pdu"
require "netsnmp/mib"
require "netsnmp/session"

require "netsnmp/scoped_pdu"
require "netsnmp/v3_session"
require "netsnmp/security_parameters"
require "netsnmp/message"
require "netsnmp/encryption/des"
require "netsnmp/encryption/aes"

require "netsnmp/client"
