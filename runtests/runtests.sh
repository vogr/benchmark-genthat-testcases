#!/usr/bin/env bash
set -u



CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

export R_LIBS="$(Rscript -e "cat(.libPaths())")"

export N_BENCHMARKS=20

process_test() {
  if [[ $1 =~ ^#.* ]]; then 
    return;
  fi

  PKG="$(realpath "$1")"
  PKG_NAME="$(basename "$PKG")"
  TEST="$(realpath "$2")"
  TEST_NAME="$(basename "$TEST")"

    
  TEST_REL="$(realpath --relative-to="$PKG" "$TEST")"
  TREE="${TEST_REL%.*}"
  DEST="tests/$PKG_NAME/$TREE"

  if [[ -d "$DEST" ]]; then
    printf "* Skipping %s\n" "$TEST"
    return
  else
    mkdir -p "$DEST" &&
    DEST="$(realpath "$DEST")"
    printf "* Test %s\n into %s\n" "$TEST" "$DEST"
  fi

  (
    cd "$DEST" &&

    LOG="runbench.log"


    # format time output
    TIMEFORMAT="    %Rs"

    # Run the file:
    #   with R (for benchmark) x N_BENCHMARKS
    #   with Rjr (for benchmark) x N_BENCHMARKS
    #   with Rrr (for benchmark) x N_BENCHMARKS
    #   with Rmr (for context logging)

    printf "* benchmark R...\n" >> "$LOG"
    mkdir -p bench-R &&
    {
      time {
        for ((i=1 ; i <= N_BENCHMARKS; i++)); do
          Rscript "$TEST" "bench-R/bench-$i.RDS" || break
        done
      } > R.log 2>&1
    } >> "$LOG" 2>&1

    printf "* benchmark Rsh RIR-only...\n" >> "$LOG"
    mkdir -p bench-rir &&
    {
      time {
        for ((i=1 ; i <= N_BENCHMARKS; i++)); do
          PIR_ENABLE=off "$HOME/bin/Rjrscript" "$TEST" "bench-rir/bench-$i.RDS" || break
        done
      } > rir.log 2>&1
    } >> "$LOG" 2>&1

    printf "* benchmark Rsh...\n" >> "$LOG"
    mkdir -p bench-Rsh &&
    {
      time {
        for ((i=1 ; i <= N_BENCHMARKS; i++)); do
          "$HOME/bin/Rjrscript" "$TEST" "bench-Rsh/bench-$i.RDS" || break
        done
      } > Rsh.log 2>&1
    } >> "$LOG" 2>&1

    printf "* context profile...\n" >> "$LOG"
    mkdir -p "profile" &&
    {
      time {
      CONTEXT_LOGS=true "$HOME/bin/Rmrscript" "$TEST" > Rm.log 2>&1
      }
    } >> "$LOG" 2>&1
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

xargs -P8 -r -n1 bash -c 'process_pkg "$@"' _ < packages.txt

printf "Done\n" > /dev/stderr
