#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

< ./packages.txt xargs -P4 -r -n1 bash -c '
  if ! [[ $1 =~ ^#.* ]]; then
    PKG="$1"
    timeout 300s ./extract-tests.R "$PKG"
  fi
  ' xargs-sh
