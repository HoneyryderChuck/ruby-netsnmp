# frozen_string_literal: true

require_relative "spec_helper"

class NETSNMPVarbindSpec < Minitest::Spec
  include NETSNMP

  describe "#to_der" do
    it { assert_equal("0\f\006\b+\006\001\002\001\001\001\000\005\000".b, Varbind.new(".1.3.6.1.2.1.1.1.0").to_der) }

    describe "application specific" do
      it "converts ip addresses" do
        ipaddr = IPAddr.new("10.11.104.2")
        varbind = Varbind.new(".1.3.6.1.4.1.2011.6.3.1.1.0", value: ipaddr)
        assert(varbind.to_der.end_with?("@\x04\n\vh\x02".b))
        asn = varbind.to_asn.value.last
        assert_equal(ipaddr, varbind.convert_application_asn(asn))
      end
      it "converts custom timeticks" do
        timetick = NETSNMP::Timetick.new(1) # yes, one timetick
        varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", value: timetick)
        assert(varbind.to_der.end_with?("\x04\x00\x00\x00\x01".b)) # ends with an octet string rep of 1 timetick
        asn = varbind.to_asn.value.last
        assert_equal(timetick, varbind.convert_application_asn(asn))
      end

      describe "when passed a type" do
        it "converts gauge32 without a leading byte" do
          gauge = 127
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :gauge, value: gauge)
          value_str = varbind.to_der[12..-1]
          header = value_str[0].unpack1("B8")

          # Class: Primitive Application
          assert_equal("01", header[0..1])
          assert_equal("0", header[2])
          # Type: Integer
          assert_equal(2, header[3..-1].to_i(2))
          # Length & Value
          assert(varbind.to_der.end_with?("\x01\x7F".b)) # 2 Bytes

          # Original Value
          asn = varbind.to_asn.value.last
          assert_equal(gauge, varbind.convert_application_asn(asn))
        end
        it "converts gauge32 with a leading byte" do
          gauge = 128
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :gauge, value: gauge)
          value_str = varbind.to_der[12..-1]
          header = value_str[0].unpack1("B8")

          # Class: Primitive Application
          assert_equal("01", header[0..1])
          assert_equal("0", header[2])
          # Type: Integer
          assert_equal(2, header[3..-1].to_i(2))
          # Length & Value
          assert(varbind.to_der.end_with?("\x02\x00\x80".b)) # 4 Bytes, all FF

          # Original Value
          asn = varbind.to_asn.value.last
          assert_equal(gauge, varbind.convert_application_asn(asn))
        end
        it "converts gauge32" do
          gauge = 805
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :gauge, value: gauge)
          value_str = varbind.to_der[12..-1]
          header = value_str[0].unpack1("B8")

          # Class: Primitive Application
          assert_equal("01", header[0..1])
          assert_equal("0", header[2])
          # Type: Integer
          assert_equal(2, header[3..-1].to_i(2))
          # Length & Value
          assert(varbind.to_der.end_with?("\x02\x03%".b))

          # Original Value
          asn = varbind.to_asn.value.last
          assert_equal(gauge, varbind.convert_application_asn(asn))
        end
        it "converts counter32 without a leading byte" do
          counter = 127
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :counter32, value: counter)
          assert(varbind.to_der.end_with?("\x01\x7F".b))
          asn = varbind.to_asn.value.last
          assert_equal(counter, varbind.convert_application_asn(asn))
        end
        it "converts counter32 with a leading byte" do
          counter = 128
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :counter32, value: counter)
          assert(varbind.to_der.end_with?("\x02\x00\x80".b))
          asn = varbind.to_asn.value.last
          assert_equal(counter, varbind.convert_application_asn(asn))
        end
        it "converts counter32" do
          counter = 998932
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :counter32, value: counter)
          assert(varbind.to_der.end_with?("\x0F>\x14".b))
          asn = varbind.to_asn.value.last
          assert_equal(counter, varbind.convert_application_asn(asn))
        end
        it "converts counter64" do
          counter = 998932
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :counter64, value: counter)
          assert(varbind.to_der.end_with?("\x0F>\x14".b))
          asn = varbind.to_asn.value.last
          assert_equal(counter, varbind.convert_application_asn(asn))

          counter = 4294967296
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :counter64, value: counter)
          assert(varbind.to_der.end_with?("\x01\x00\x00\x00\x00".b))
          asn = varbind.to_asn.value.last
          assert_equal(counter, varbind.convert_application_asn(asn))

          counter = 309084502
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :counter64, value: counter)
          assert_includes(varbind.to_der, "F\x04".b)
          asn = varbind.to_asn.value.last
          assert_equal(counter, varbind.convert_application_asn(asn))

          counter = 2_613_579_752_238
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :counter64, value: counter)
          assert_includes(varbind.to_der, "F\x06".b)
          asn = varbind.to_asn.value.last
          assert_equal(counter, varbind.convert_application_asn(asn))
        end
        it "converts integer ticks" do
          timetick = 1
          varbind = Varbind.new(".1.3.6.1.2.1.1.3.0", type: :timetick, value: timetick)
          assert(varbind.to_der.end_with?("\x04\x00\x00\x00\x01".b))
          asn = varbind.to_asn.value.last
          assert_equal(timetick, varbind.convert_application_asn(asn))
        end
      end
    end
  end
end
