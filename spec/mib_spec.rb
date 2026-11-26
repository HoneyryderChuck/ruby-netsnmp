# frozen_string_literal: true

require_relative "spec_helper"

class NETSNMPMIBSpec < Minitest::Spec
  include NETSNMP

  describe ".oid" do
    it { assert_equal("1.2.3.4", MIB.oid("1.2.3.4")) }
    it { assert_equal("1.3.6.1.2.1.2.2", MIB.oid("ifTable")) }
    it { assert_equal("1.3.6.1.2.1.1.1.0", MIB.oid("sysDescr.0")) }
    it { assert_equal("1.3.6.1.2.1.2.2.1.23", MIB.oid("ifTable.1.23")) }
    it { assert_equal("1.3.6.1.2.1.2.2.1.23", MIB.oid("IF-MIB::ifTable.1.23")) }
    it { assert_nil(MIB.oid("IFMIB::ifTable.1.23")) }
    it { assert_nil(MIB.oid("IF-MIB::")) }
  end
end
