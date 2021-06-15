#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

export SRC="$(realpath "../runtests/tests")"


process_dir () {
  DIR="$(dirname "$(realpath "$1")")"
  printf "Processing %s ..." "$DIR"

  REL="$(realpath --relative-to="$SRC" "$DIR")"
  DEST_DIR="graphs/$REL"
  DEST="$DEST_DIR/runtimes.pdf"

  mkdir -p "$DEST_DIR"

  Rscript make_graph.R "$DIR" "$DEST"
}
export -f process_dir

echo "$SRC"
find "$SRC" -name "R.log" -type f -print0 |
  xargs -P4 -r0 -n1 bash -c 'process_dir "$@"' "xargs-sh"

#find "$SRC" -name 'R.log' -type f -print 0 |
  #xargs -r0 echo
  #xargs -r0 -I{} bash -c 'process_dir "$@"' _
