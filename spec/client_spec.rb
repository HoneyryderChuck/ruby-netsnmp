# frozen_string_literal: true

require_relative "spec_helper"
require_relative "support/request_examples"

class NETSNMPClientSpec < Minitest::Spec
  let(:host) { SNMPHOST }

  let(:device_options) do
    {
      peername: SNMPHOST,
      port: SNMPPORT
    }
  end
  describe "v1" do
    include RequestExamples

    let(:protocol_options) do
      {
        version: "1",
        community: "public"
      }
    end
    let(:get_oid) { "1.3.6.1.2.1.1.5.0" }
    let(:next_oid) { "1.3.6.1.2.1.1.6.0" }
    let(:walk_oid) { "1.3.6.1.2.1.1" }
    let(:set_oid) { "sysUpTime.0" } # sysUpTimeInstance
    let(:get_result) { "zeus.snmplabs.com (you can change this!)" }
    let(:next_result) { "San Francisco, California, United States" }
    let(:walk_result) do
      {
        "1.3.6.1.2.1.1.1.0" => "Linux zeus 4.8.6.5-smp #2 SMP Sun Nov 13 14:58:11 CDT 2016 i686",
        "1.3.6.1.2.1.1.2.0" => "1.3.6.1.4.1.8072.3.2.10",
        "1.3.6.1.2.1.1.3.0" => /Timeticks: \(\d+\) \d+ days, \d+:\d+:\d+\.\d+/,
        "1.3.6.1.2.1.1.4.0" => "SNMP Laboratories, info@snmplabs.com",
        "1.3.6.1.2.1.1.5.0" => "zeus.snmplabs.com (you can change this!)",
        "1.3.6.1.2.1.1.6.0" => "San Francisco, California, United States",
        "1.3.6.1.2.1.1.7.0" => "72",
        "1.3.6.1.2.1.1.8.0" => /Timeticks: \(\d+\) \d+ days, \d+:\d+:\d+\.\d+/
      }
    end
    let(:set_oid_result) { 43 }
  end
  describe "v2" do
    include RequestExamples

    let(:protocol_options) do
      {
        version: "2c",
        community: "public"
      }
    end
    let(:get_oid) { "sysName.0" }
    let(:next_oid) { "1.3.6.1.2.1.1.6.0" }
    let(:walk_oid) { "system" }
    let(:set_oid) { "sysUpTime.0" }
    let(:get_result) { "zeus.snmplabs.com (you can change this!)" }
    let(:next_result) { "San Francisco, California, United States" }
    let(:walk_result) do
      {
        "1.3.6.1.2.1.1.1.0" => "Linux zeus 4.8.6.5-smp #2 SMP Sun Nov 13 14:58:11 CDT 2016 i686",
        "1.3.6.1.2.1.1.2.0" => "1.3.6.1.4.1.8072.3.2.10",
        "1.3.6.1.2.1.1.3.0" => /Timeticks: \(\d+\) \d+ days, \d+:\d+:\d+\.\d+/,
        "1.3.6.1.2.1.1.4.0" => "SNMP Laboratories, info@snmplabs.com",
        "1.3.6.1.2.1.1.5.0" => "zeus.snmplabs.com (you can change this!)",
        "1.3.6.1.2.1.1.6.0" => "San Francisco, California, United States",
        "1.3.6.1.2.1.1.7.0" => "72",
        "1.3.6.1.2.1.1.8.0" => /Timeticks: \(\d+\) \d+ days, \d+:\d+:\d+\.\d+/
      }
    end
    let(:set_oid_result) { 43 }

    describe "when the returned result is a hex-string" do
      let(:protocol_options) do
        {
          version: "2c",
          community: "foreignformats/winxp1"
        }
      end
      let(:hex_get_oid) { "1.3.6.1.2.1.25.3.7.1.3.10.1" }
      let(:hex_get_result) { "\x01\x00\x00\x00" }
      let(:hex_get_output) { "01 00 00 00" }
      let(:result) { subject.get(oid: hex_get_oid) }

      it "returns the string, which outputs the hex-representation" do
        assert_equal(hex_get_result, result)
        assert_includes(result.inspect, hex_get_output)
      end
    end
  end

  describe "v3" do
    let(:extra_options) { {} }
    let(:version_options) do
      {
        version: "3",
        context: "a172334d7d97871b72241397f713fa12"
      }
    end
    let(:get_oid) { "sysName.0" }
    let(:next_oid) { "1.3.6.1.2.1.1.6.0" }
    let(:set_oid) { "sysUpTime.0" } # sysUpTimeInstance
    let(:walk_oid) { "1.3.6.1.2.1.1.9.1.3" }
    let(:get_result) { "tt" }
    let(:next_result) { "KK12 (edit /etc/snmp/snmpd.conf)" }
    let(:walk_result) do
      {
        "1.3.6.1.2.1.1.9.1.3.1" => "The SNMP Management Architecture MIB.",
        "1.3.6.1.2.1.1.9.1.3.2" => "The MIB for Message Processing and Dispatching.",
        "1.3.6.1.2.1.1.9.1.3.3" => "The management information definitions for the SNMP User-based Security Model.",
        "1.3.6.1.2.1.1.9.1.3.4" => "The MIB module for SNMPv2 entities",
        "1.3.6.1.2.1.1.9.1.3.5" => "The MIB module for managing TCP implementations",
        "1.3.6.1.2.1.1.9.1.3.6" => "The MIB module for managing IP and ICMP implementations",
        "1.3.6.1.2.1.1.9.1.3.7" => "The MIB module for managing UDP implementations",
        "1.3.6.1.2.1.1.9.1.3.8" => "View-based Access Control Model for SNMP."
      }
    end
    let(:set_oid_result) { 43 }
    describe "with a no auth no priv policy" do
      let(:user_options) { { username: "unsafe", security_level: :noauth } }

      include RequestExamples

      let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      # why is this here? that variation/notification community causes the simulagtor to go down
      # until I find the origin of the issue and patched it with an appropriated community, this
      # is here so that I test the set call at least once, although I'm sure it'll work always
      # for v3
      describe "#set" do
        let(:extra_options) { { context: "0886e1397d572377c17c15036a1e6c66" } }
        it "updates the value of the oid" do
          prev_value = subject.get(oid: set_oid)
          assert_instance_of(Integer, prev_value)

          # without type
          subject.set(oid: set_oid, value: set_oid_result)
          assert_equal(set_oid_result, subject.get(oid: set_oid))

          subject.set(oid: set_oid, value: prev_value)
        end
      end
    end
    describe "with an only auth policy" do
      describe "speaking md5" do
        let(:user_options) do
          { username: "authmd5", security_level: :auth_no_priv,
            auth_password: "maplesyrup", auth_protocol: :md5 }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      end
      describe "speaking sha" do
        let(:user_options) do
          { username: "authsha", security_level: :auth_no_priv,
            auth_password: "maplesyrup", auth_protocol: :sha }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      end
      describe "speaking sha224" do
        let(:user_options) do
          { username: "authsha224", security_level: :auth_no_priv,
            auth_password: "maplesyrup", auth_protocol: :sha224 }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      end
      describe "speaking sha384" do
        let(:user_options) do
          { username: "authsha384", security_level: :auth_no_priv,
            auth_password: "maplesyrup", auth_protocol: :sha384 }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      end
      describe "speaking sha256" do
        let(:user_options) do
          { username: "authsha256", security_level: :auth_no_priv,
            auth_password: "maplesyrup", auth_protocol: :sha256 }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      end
      describe "speaking sha512" do
        let(:user_options) do
          { username: "authsha512", security_level: :auth_no_priv,
            auth_password: "maplesyrup", auth_protocol: :sha512 }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      end
    end
    describe "with an auth priv policy" do
      describe "auth in md5, encrypting in des" do
        let(:user_options) do
          { username: "authprivmd5des", auth_password: "maplesyrup",
            auth_protocol: :md5, priv_password: "maplesyrup",
            priv_protocol: :des }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      end
      describe "auth in sha, encrypting in des" do
        let(:user_options) do
          { username: "authprivshades", auth_password: "maplesyrup",
            auth_protocol: :sha, priv_password: "maplesyrup",
            priv_protocol: :des }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }

        describe "with wrong auth password and wrong encrypting password" do
          let(:user_options) do
            { username: "authprivmd5des", auth_password: "wrongpassword",
              auth_protocol: :md5, priv_password: "maplesyrup",
              priv_protocol: :des }
          end
          let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
          it "raises authentication error" do
            e = assert_raises(NETSNMP::Error) { subject.get(oid: get_oid) }
            assert_includes(e.message, "Authentication failure (incorrect password, community or key)")
          end
        end
      end

      describe "auth in md5, encrypting in aes" do
        let(:user_options) do
          { username: "authprivmd5aes", auth_password: "maplesyrup",
            auth_protocol: :md5, priv_password: "maplesyrup",
            priv_protocol: :aes }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
      end
      describe "auth in sha, encrypting in aes" do
        let(:user_options) do
          { username: "authprivshaaes", auth_password: "maplesyrup",
            auth_protocol: :sha, priv_password: "maplesyrup",
            priv_protocol: :aes }
        end
        include RequestExamples

        let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
        describe "auth in sha224, encrypting in aes" do
          let(:user_options) do
            { username: "authprivsha224aes", auth_password: "maplesyrup",
              auth_protocol: :sha224, priv_password: "maplesyrup",
              priv_protocol: :aes }
          end
          include RequestExamples

          let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
        end
        describe "auth in sha384, encrypting in aes192" do
          let(:user_options) do
            { username: "authprivsha384aes192", auth_password: "maplesyrup",
              auth_protocol: :sha384, priv_password: "maplesyrup",
              priv_protocol: :aes192 }
          end
          include RequestExamples

          let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
        end
        describe "auth in sha512, encrypting in aes256" do
          let(:user_options) do
            { username: "authprivsha512aes256", auth_password: "maplesyrup",
              auth_protocol: :sha512, priv_password: "maplesyrup",
              priv_protocol: :aes256 }
          end
          include RequestExamples

          let(:protocol_options) { version_options.merge(user_options).merge(extra_options) }
        end
      end
    end
  end
end
