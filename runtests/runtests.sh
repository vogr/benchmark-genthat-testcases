#!/usr/bin/env bash
set -u



CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

export R_LIBS="$HOME/.Renv/versions/3.6.2/lib/R/library"

export N_BENCHMARKS=100


process_test() {
  if [[ $1 =~ ^#.* ]]; then 
    return;
  fi

  PKG="$(realpath "$1")"
  PKG_NAME="$(basename "$PKG")"
  TEST="$(realpath "$2")"
  TEST_NAME="$(basename "$TEST")"

  printf "* Test %s\n" "$TEST"
    
  TEST_REL="$(realpath --relative-to="$PKG" "$TEST")"
  TREE="${TEST_REL%.*}"
  DEST="tests/$PKG_NAME/$TREE"

  printf "  into %s\n" "$DEST"

  mkdir -p "$DEST" &&
  (
    cd "$DEST" &&

    # Run the file:
    #   with R (for benchmark) x N_BENCHMARKS
    #   with Rjr (for benchmark) x N_BENCHMARKS
    #   with Rmr (for context logging)

    printf "  + benchmark R...\n"
    mkdir -p bench-R &&
    (
      for ((i=1 ; i <= N_BENCHMARKS; i++)); do
        Rscript "$TEST" "bench-R/bench-$i.RDS" || break
      done
    ) > R.log 2>&1

    printf "  + benchmark Rsh...\n"
    mkdir -p bench-Rsh &&
    (
      for ((i=1 ; i <= N_BENCHMARKS; i++)); do
        "$HOME/bin/Rjrscript" "$TEST" "bench-Rsh/bench-$i.RDS" || break
      done
    ) > Rsh.log 2>&1

    #printf "  + context profile...\n"
    #mkdir "profile" &&
    #"$HOME/bin/Rmrscript" "$TEST" > Rm.log 2>&1
  )
}
export -f process_test

process_pkg () {
  PKG="$(realpath "$1")"
  PKGNAME="$(basename "$PKG")"

  printf "Processing %s...\n" "$PKGNAME"

  find "$PKG" -type f -name "*.R" -print0 |
      sort -z |
      xargs -r0 -n1 bash -c 'process_test "$@"' _ "$PKG"
}
export -f process_pkg

xargs -r -n1 bash -c 'process_pkg "$@"' _ < packages.txt

printf "Done\n" > /dev/stderr
