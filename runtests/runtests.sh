#!/usr/bin/env bash
set -u



CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

export R_LIBS="$(Rscript -e "cat(.libPaths())")"

export N_BENCHMARKS=3
export TIMEOUT=200
export SKIP_FAILED=false

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

  if [[ -f "$DEST/DATA_READY" ]]; then
    printf "* Already processed %s\n" "$TEST"
    return
  fi

  if [[ "$SKIP_FAILED" = "true" && -f "$DEST/FAILED" ]]; then
    printf "Skipping failed test\n"
    return;
  fi

  mkdir -p "$DEST" &&
  DEST="$(realpath "$DEST")"

  printf "* Test %s\n into %s\n" "$TEST" "$DEST"

  if [[ -f "$DEST/FAILED" ]]; then
    printf "   (resetting failed status)\n"
    rm "$DEST/FAILED"
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
          timeout "$TIMEOUT" Rscript "$TEST" "bench-R/bench-$i.RDS" ||
            { echo "R" >> FAILED && break; }
        done
      } > R.log 2>&1
    } >> "$LOG" 2>&1

    printf "* benchmark Rsh RIR-only...\n" >> "$LOG"
    mkdir -p bench-rir &&
    {
      time {
        for ((i=1 ; i <= N_BENCHMARKS; i++)); do
          PIR_ENABLE=off timeout "$TIMEOUT" "$HOME/bin/Rjrscript" "$TEST" "bench-rir/bench-$i.RDS" ||
            { echo "rir" >> FAILED && break; }
        done
      } > rir.log 2>&1
    } >> "$LOG" 2>&1

    printf "* benchmark Rsh...\n" >> "$LOG"
    mkdir -p bench-Rsh &&
    {
      time {
        for ((i=1 ; i <= N_BENCHMARKS; i++)); do
          timeout "$TIMEOUT" "$HOME/bin/Rjrscript" "$TEST" "bench-Rsh/bench-$i.RDS" ||
            { echo "Rsh" >> FAILED && break; }
        done
      } > Rsh.log 2>&1
    } >> "$LOG" 2>&1

    printf "* context profile...\n" >> "$LOG"
    mkdir -p "profile" &&
    {
      time {
      {
        CONTEXT_LOGS=true timeout "$TIMEOUT" "$HOME/bin/Rmrscript" "$TEST" ||
          echo "Rsh+context profile" >> FAILED
      } > Rm.log 2>&1
      }
    } >> "$LOG" 2>&1

    if [[ ! -f FAILED ]]; then
      touch DATA_READY
    fi
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

xargs -P16 -r -n1 bash -c 'process_pkg "$@"' _ < packages.txt

printf "Done\n" > /dev/stderr
