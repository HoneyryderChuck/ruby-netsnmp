#!/bin/bash

set -e

RUBY_ENGINE=`ruby -e 'puts RUBY_ENGINE'`

if [[ "$RUBY_ENGINE" = "truffleruby" ]]; then
  dnf install -y git net-snmp-utils
elif [[ "$RUBY_ENGINE" = "jruby" ]]; then
  apt-get update
  apt-get install -y snmp-mibs-downloader
else
echo "
deb http://deb.debian.org/debian/ buster main contrib non-free
deb http://deb.debian.org/debian/ buster-updates main contrib non-free" >> /etc/apt/sources.list

  apt-get update
  apt-get install -y snmp-mibs-downloader
fi

gem install bundler -v="1.17.3" --no-doc --conservative
cd /home

bundle -v
bundle install

touch openssl_legacy.cnf
cat <<EOT > openssl_legacy.cnf
.include = /usr/lib/ssl/openssl.cnf

[openssl_init]
providers = provider_sect

[provider_sect]
default = default_sect
legacy = legacy_sect

[default_sect]
activate = 1

[legacy_sect]
activate = 1
EOT
export OPENSSL_CONF=/home/openssl_legacy.cnf


if [[ ${RUBY_VERSION:0:1} = "3" ]]; then
  export RUBYOPT='-rbundler/setup -rrbs/test/setup'
  export RBS_TEST_RAISE=true
  export RBS_TEST_LOGLEVEL=error
  export RBS_TEST_OPT='-Isig -ripaddr -ropenssl -rsocket'
  export RBS_TEST_TARGET='NETSNMP*'
fi

bundle exec rake spec:ci
