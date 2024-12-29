#!/usr/bin/env bash

set -xEeuo pipefail

PREFIX=/usr/libexec/omnipackage-agent-ruby/ruby

if $PREFIX/bin/ruby -v; then
  exit 0
fi

curl -L https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.1.tar.gz | tar -zx -C .
cd ruby-3.4.1/
./configure --disable-install-doc --prefix=$PREFIX
make -j$(nproc)
make install
cd ..
rm -rf ruby-3.4.1/
ls -latrh $PREFIX
