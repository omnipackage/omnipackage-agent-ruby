#!/usr/bin/env bash

set -xEeuo pipefail

BUILDROOT=$1
PREFIX="/usr"
LIBDIR="$PREFIX/libexec/omnipackage-agent-ruby"
BINDIR="$PREFIX/bin"
VENDORED_RUBY_DIR="$LIBDIR/ruby"

install -d -m755 $BUILDROOT/$LIBDIR
install -d -m755 $BUILDROOT/$BINDIR
cp -R $(ls -I ".omnipackage" -I ".gitignore" -I ".ruby-version" -I "node_modules" -I "debian") $BUILDROOT/$LIBDIR

if [ -d $VENDORED_RUBY_DIR ]; then
  cp -R $VENDORED_RUBY_DIR $BUILDROOT/$LIBDIR
  cd $BUILDROOT/$LIBDIR
  ls -latrh .

  sed -i "s|#!/usr/bin/env ruby|#!/usr/bin/env $VENDORED_RUBY_DIR/bin/ruby|g" exe/omnipackage
  sed -i "s|#!/usr/bin/env ruby|#!/usr/bin/env $VENDORED_RUBY_DIR/bin/ruby|g" exe/omnipackage-agent
fi

ln -s $LIBDIR/exe/omnipackage $BUILDROOT$BINDIR
ln -s $LIBDIR/exe/omnipackage-agent $BUILDROOT$BINDIR
