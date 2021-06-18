#!/usr/bin/env Rscript

library(tibble)
library(dplyr)
library(readr)

TESTS_DIR <- "../runtests/tests"

data_ready_dirs <- normalizePath(dirname(dir(TESTS_DIR, pattern = "DATA_READY", recursive=TRUE, full.names=TRUE)))


message("Merge data from ", length(data_ready_dirs), " test runs.")


read_and_prepare <- function(d) {

  test_fname <- basename(d)
  test_fun <- basename(dirname(d))
  test_pkg <- basename(dirname(dirname(d)))

  # ID is a size_t and can be larger than R int type, so use a string
  read_csv(file.path(d, "profile", "compile_stats.csv"), col_types="cccild") %>%
    mutate(test_pkg=test_pkg, test_fun=test_fun, test_fname=test_fname, .before="ID")
}

# Bind all csv.s together
df <- bind_rows(lapply(data_ready_dirs, read_and_prepare))

write_csv(df, "all.csv")
