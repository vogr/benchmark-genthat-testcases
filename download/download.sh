#!/usr/bin/env bash
set -u

CWD="$(dirname "$(readlink -f "$0")")"
cd "$CWD" || exit 1

download_pkg () {
  IFS=, read PKG VERSION <<< "$1"

  mkdir -p "../CRAN" &&

  #Rscript -e "download.packages('$PKG', destdir='../CRAN', repos='https://cloud.r-project.org/')"

  if [[ $VERSION == "NULL" ]]; then
    printf "Downloading latest %s\n" "$PKG" &&
    Rscript -e "genthat::download_package('$PKG', '../CRAN', repos='https://cloud.r-project.org/', quiet=FALSE)"
  else
    printf "Downloading %s v. %s\n" "$PKG" "$VERSION" &&
    Rscript -e "genthat::download_package('$PKG', '../CRAN', repos='https://cloud.r-project.org/', version=\"$VERSION\", quiet=FALSE)"
  fi
}
export -f download_pkg

xargs -r -n1 -P4 bash -c 'download_pkg "$@"' _

