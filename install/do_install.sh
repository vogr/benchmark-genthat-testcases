#!/usr/bin/env bash

set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

xargs -I{} Rscript -e 'devtools::install_local("{}",force=TRUE)' < ./packages.txt
