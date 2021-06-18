#!/usr/bin/env Rscript

library(tibble)
library(dplyr)
library(readr)
library(ggplot2)

TESTS_DIR <- "../runtests/tests"

data_ready_dirs <- normalizePath(dirname(dir(TESTS_DIR, pattern = "DATA_READY", recursive=TRUE, full.names=TRUE)))
data_ready_dirs <- data_ready_dirs[1:100]


read_and_prepare <- function(d) {

  test_fname <- basename(d)
  test_fun <- basename(dirname(d))
  test_pkg <- basename(dirname(dirname(d)))

  # ID is a size_t and can be larger than R int type, so use a string
  read_csv(file.path(d, "profile", "compile_stats.csv"), col_types="cccild") %>%
    mutate(test_pkg=test_pkg, test_fun=test_fun, test_fname=test_fname, .before="ID")
}

# Bind all csv.s together
# Keep only su
df <- bind_rows(lapply(data_ready_dirs, read_and_prepare))


successes <- df %>% filter(SUCCESS == TRUE)
failures <- df %>% filter(SUCCESS == FALSE)


write_csv(successes, "successes.csv")
write_csv(failures, "failures.csv")



