#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

(find "../CRAN" -mindepth 1 -maxdepth 1 -print0 | sort -z | xargs -r0 -n1 printf "%s\n") > packages.txt
