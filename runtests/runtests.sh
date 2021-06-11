#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

export R="$HOME/bin/Rmrscript"


find tests -mindepth 1 -maxdepth 1 -type d -print0 |
  sort -z |
  xargs -P4 -r0 -n1 bash -c '
cd $1 &&
mkdir -p profile &&
printf "running %s...\n" "$1"
export CONTEXT_LOGS=true PIR_DEBUG=ShowWarnings
timeout 10m $R -f main.R > run.log 2>&1
' xargs-sh
