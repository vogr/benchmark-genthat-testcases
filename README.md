# Benchmarking genthat testcases

## Prerequisites

### R and Ř

This project was tested with R 3.6.2. You can get this version of R using [R-build](https://github.com/viking/R-build), and activate it using [Renv](https://github.com/viking/Renv).

You will also need variants of `Rscript` available under alias names (bash alias or script)

- the Ř compiler under the name `Rjrscript`
- the Ř compiler with contextual profiler with the name `Rmrscript`

For instance, in `$HOME/bin/Rjrscript`, I have

```sh
#!/bin/sh

"$HOME/PRL-PRG/rir/build/release/bin/Rscript" "$@"
```

### Required packages

```console
$ R
> install.packages("devtools")
> devtools::install_github("https://github.com/vogr/genthat/tree/genthat-for-profiling")
```

## Downloading the CRAN packages

```console
$ cd download

# Download the latest versions
$ ./download.sh < packages.txt

# Download the pinned-down versions
$ ./download.sh < packages.txt.lock
```

You can remove the `tar.gz` files:

```console
$ find CRAN -maxdepth 1 -type f -name "*.tar.gz" -print0 | xargs -r0 rm
```


## Install the packages

```console
$ cd install

# generate the list of available packages
$ ./gen_packages.sh

# You can edit the file packages.txt to remove
# or comment out (with '#') packages

# Install the selected packages
$ ./do_install.sh
```

Note: the packages will be installed using R into the default library path:

```console
$ Rscript -e ".libPaths()"
```

Note: you can now pin down the versions that you have installed

```console
$ cd download
$ ./gen_packages_locked.sh > packages.txt.lock
```

## Generate the testcases

```console
$ cd testcases
$ ./generate_packages.sh
$ ./gen_testcases.sh
```

## Run the tests

Each test file runs the function to test 50 times and saves the runtime of each iteration in a table.

The test files will be run 20 times, resulting in 20 tables with 50 entries each, per test file, saved as `.RDS` files.

```console
$ cd runtests
$ ./gen_packages.sh
$ ./runtests.sh
```

## Make the graphs

```console
$ cd make_graphs
$ ./make_graphs.sh
```
