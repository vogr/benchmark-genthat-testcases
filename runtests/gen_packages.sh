#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

(
find "../testcases/experiment" -mindepth 1 -maxdepth 1 -type d -print0 | \
  sort -z | \
  xargs -r0 -n1 printf "%s\n"
) > packages.txt
