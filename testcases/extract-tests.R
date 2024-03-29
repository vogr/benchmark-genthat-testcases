#!/usr/bin/env Rscript

library(methods)
library(genthat)
library(covr)


CRAN=normalizePath("../CRAN")

options(genthat.source_paths=CRAN)
options(genthat.debug=TRUE)
options(genthat.keep_failed_tests=FALSE)
options(genthat.keep_all_traces=FALSE)
options(genthat.max_trace_size=getOption("genthat.max_trace_size", 512*1024))

package <- commandArgs(trailingOnly=TRUE)


outdir_name <- "experiment"
if(!dir.exists(outdir_name))
  dir.create(outdir_name)
output_dir <- normalizePath(outdir_name)

#tests_file <- file.path(output_dir, "tests.RDS")
#tests_coverage_file <- file.path(output_dir, "coverage.RDS")

# running the tests sometimes creates files: go into a temporary directory
setwd(tempdir())

with_time <- function(expr) {
  time <- genthat:::stopwatch(result <- force(expr))
  attr(result, "time") <- time
  result
}


# /!\ quiet = false is buggy with packages that test for interractive output

if (!file.exists(file.path(output_dir, package))) {
  message("Generating tests for ", package)
  tests <- with_time(gen_from_package(package, types="all", action="generate", prune_tests=TRUE, output_dir=output_dir,quiet=TRUE))
  #saveRDS(tests, tests_file)
} else {
  message("Skipping package ", package, ": output directory exists")
}

#if (!file.exists(tests_coverage_file)) {
#  tests_coverage <- with_time(tally_coverage(package_coverage(file.path(CRAN, package), type="tests"))
#}
