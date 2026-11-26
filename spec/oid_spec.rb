# frozen_string_literal: true

require_relative "spec_helper"

class NETSNMPOIDSpec < Minitest::Spec
  include NETSNMP

  # let(:code) { "SNMPv2-MIB::sysDescr.0" }
  let(:code) { "1.3.6.1.2.1.1.1.0" }
  subject { OID.build(code) }

  describe ".build" do
    it { assert_equal(code, OID.build([1, 3, 6, 1, 2, 1, 1, 1, 0]).to_s) }
    it { assert_equal(code, OID.build(".#{code}").to_s) }
    it { assert_raises(NETSNMP::Error) { OID.build("blablabla") } }
  end

  describe ".to_asn" do
    it { assert_equal("\x06\b+\x06\x01\x02\x01\x01\x01\x00".b, OID.to_asn(subject).to_der) }
  end
end
