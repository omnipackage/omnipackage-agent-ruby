#!/usr/bin/env bash

set -xEeuo pipefail

# libyaml-devel is not available in default repositories, but libyml is
dnf install -y --allowerasing 'dnf-command(config-manager)'
dnf config-manager --set-enabled powertools
dnf install -y --allowerasing libyaml-devel

$(dirname $0)/install_ruby.sh
