#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

export SRC="$(realpath "../runtests/tests")"
export DEST_DIR="graphs/"

mkdir -p "$DEST_DIR"

process_dir () {
  DIR="$(dirname "$(realpath "$1")")"

  REL="$(realpath --relative-to="$SRC" "$DIR")"

  TEST="$(basename "$DIR")"
  FUN="$(basename "$(dirname "$DIR")")"
  PKG="$(basename "$(dirname "$(dirname "$DIR")")")"

  DEST="$DEST_DIR/$PKG::${FUN}__$TEST.pdf"


  if [[ ! -f "$DIR/DATA_READY" ]]; then
    printf "Skip: Not ready %s\n" "$DIR"
    return
  fi

  if [[ -f "$DEST" ]]; then
    printf "Skip: Already processed %s\n" "$DIR"
    return
  else
    printf "Processing %s ...\n" "$DIR"
  fi
  mkdir -p "$DEST_DIR"

  Rscript make_graph.R "$DIR" "$DEST"
}
export -f process_dir

echo "$SRC"
find "$SRC" -name "R.log" -type f -print0 |
  xargs -P16 -r0 -n1 bash -c 'process_dir "$@"' "xargs-sh"

#find "$SRC" -name 'R.log' -type f -print 0 |
  #xargs -r0 echo
  #xargs -r0 -I{} bash -c 'process_dir "$@"' _
