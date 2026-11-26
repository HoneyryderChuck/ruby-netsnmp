# frozen_string_literal: true

require_relative "spec_helper"

class NETSNMPPDUSpec < Minitest::Spec
  include NETSNMP

  let(:get_request_oid) { ".1.3.6.1.2.1.1.1.0" }
  let(:encoded_get_pdu) do
    "0'\002\001\000\004\006public\240\032\002\002?*\002\001\000\002\001\0000\0160\f\006\b+\006\001\002\001\001\001\000\005\000"
  end
  let(:encoded_response_pdu) do
    "0+\002\001\000\004\006public\242\036\002\002'\017\002\001\000\002\001\0000\0220\020\006\b+\006\001\002\001\001\001\000\004\004test"
  end

  describe "#to_der" do
    let(:pdu_get) do
      PDU.build(:get, version: 0,
                      community: "public",
                      request_id: 16170)
    end

    describe "v1" do
      before { pdu_get.add_varbind(oid: get_request_oid) }
      it { assert_equal(encoded_get_pdu.b, pdu_get.to_der) }
    end
  end

  describe "#decoding pdus" do
    describe "v1" do
      let(:pdu_response) { PDU.decode(encoded_response_pdu) }
      it { assert_equal(0, pdu_response.version) }
      it { assert_equal("public", pdu_response.community) }
      it { assert_equal(9999, pdu_response.request_id) }

      it { assert_equal(1, pdu_response.varbinds.length) }
      it { assert_equal("1.3.6.1.2.1.1.1.0", pdu_response.varbinds[0].oid) }
      it { assert_equal("test", pdu_response.varbinds[0].value) }
    end
  end
end
