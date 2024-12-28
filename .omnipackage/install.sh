#!/usr/bin/env bash

set -xEeuo pipefail

BUILDROOT=$1
PREFIX="/usr"
LIBDIR="$PREFIX/libexec/omnipackage-agent-ruby"
BINDIR="$PREFIX/bin"

install -d -m755 $BUILDROOT/$LIBDIR
install -d -m755 $BUILDROOT/$BINDIR
cp -R $(ls -I ".omnipackage" -I ".gitignore" -I ".ruby-version" -I "node_modules" -I "debian") $BUILDROOT/$LIBDIR

ln -s $LIBDIR/exe/omnipackage $BUILDROOT$BINDIR
ln -s $LIBDIR/exe/omnipackage-agent $BUILDROOT$BINDIR
