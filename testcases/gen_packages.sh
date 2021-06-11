#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

(
find "../CRAN" -mindepth 1 -maxdepth 1 |
    xargs -r -n1 basename | sort | xargs -n1 printf "%s\n"
) > packages.txt
