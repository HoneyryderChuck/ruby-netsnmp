# frozen_string_literal: true

module NETSNMP
  # Abstracts the OID structure
  #
  module OID
    OIDREGEX = /^[\d.]*$/.freeze #: Regexp

    module_function

    #: (oid) -> String
    def build(id)
      oid = MIB.oid(id)

      raise Error, "no OID found for #{id}" unless oid

      oid = oid.delete_prefix(".") if oid.start_with?(".")
      oid
    end

    #: (String oid) -> OpenSSL::ASN1::ObjectId
    def to_asn(oid)
      OpenSSL::ASN1::ObjectId.new(oid)
    end

    # @param [OID, String] child oid another oid
    # @return [true, false] whether the given OID belongs to the sub-tree
    #
    #: (String oid, String oid) -> bool
    def parent?(parent_oid, child_oid)
      child_oid.match?(/\A#{parent_oid}\./)
    end
  end
end
