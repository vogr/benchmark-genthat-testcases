#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

process_pkg () {
  SRC="$1"
  PKG="$(basename "$1")"

  printf "%s,NULL\n" "$PKG"
}
export -f process_pkg


find "../CRAN" -mindepth 1 -maxdepth 1 -type d -print0 |
  sort -z |
  xargs -r0 -n1 bash -c 'process_pkg "$@"' _
