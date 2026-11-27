# frozen_string_literal: true

target :lib do
  check "lib"
  signature "sig", "sig_stubs"

  library "forwardable", "ipaddr", "socket", "openssl", "timeout", "securerandom"
  # library "forwardable", "uri", "json", "ipaddr", "pathname", "time"

  collection_config "rbs_collection.yaml"

  ignore "lib/netsnmp/mib/parser.rb"
  ignore "lib/netsnmp/extensions.rb"
end
