#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

printf "Generating main.R\n" > /dev/stderr

< packages.txt xargs -r -n1 bash -c '
    if ! [[ $1 =~ ^#.* ]]; then 
      PKGNAME="$(basename $1)"
      printf "%s...\n" "$PKGNAME"
      mkdir -p "tests/$PKGNAME"
      (
        cd "tests/$PKGNAME"
        (
          printf ".libPaths(\"~/.Renv/versions/3.6.2/lib/R/library\")\n"
          printf "library(genthat)\n"
          printf "for(i in 1:10) {\n"
          find "$1" -type f -name "*.R" -print0 |
            sort -z |
            xargs -r0 -n1 printf "  try(test_generated_file(\"%s\"))\n"
          printf "}\n"
        ) > main.R
      ) 
    fi
' "xargs-sh"


printf "Done. Now run\n" > /dev/stderr
printf "\t./runtests.sh\n" > /dev/stderr
