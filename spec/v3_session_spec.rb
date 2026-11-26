# frozen_string_literal: true

require_relative "spec_helper"

class NETSNMPV3SessionSpec < Minitest::Spec
  include NETSNMP

  let(:security_options) do
    { username: "authprivmd5des", auth_password: "maplesyrup",
      auth_protocol: :md5, priv_password: "maplesyrup",
      priv_protocol: :des, security_level: :auth_priv }
  end
  it "generates the security parameters handler" do
    sess = V3Session.new(**security_options, host: SNMPHOST, port: SNMPPORT)
    # not generated yet
    assert_instance_of(NETSNMP::SecurityParameters, sess.instance_variable_get(:@security_parameters))
  end

  it "allows to pass a custom one" do
    sec_params = SecurityParameters.new(**security_options)
    sess = V3Session.new(host: SNMPHOST, port: SNMPPORT, security_parameters: sec_params)
    # not generated yet
    assert_equal(sec_params, sess.instance_variable_get(:@security_parameters))
  end

  it "fails if the pass object doesn't follow the expected api" do
    assert_raises(NETSNMP::Error) { V3Session.new(host: SNMPHOST, port: SNMPPORT, security_parameters: Object.new) }
  end
end
