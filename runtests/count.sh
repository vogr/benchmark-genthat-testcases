#!/usr/bin/env bash


NFAIL="$(find "tests" -name "FAILED" -printf '.' | wc -c)"
NSUCCESS="$(find "tests" -name "DATA_READY" -printf '.' | wc -c)"

printf "Failures: %s\n" "$NFAIL"
printf "Successes: %s\n" "$NSUCCESS"
