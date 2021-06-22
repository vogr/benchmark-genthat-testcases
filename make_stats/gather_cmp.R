#!/usr/bin/env Rscript

# fread and fwrite are faster than their equivalent in readr
# data.table::rbindlist is faster than tibble::bind_rows
# This makes data.table a much better fit for this simple task


library(data.table)
library(tibble)

TESTS_DIR <- "../runtests/tests"

if (!dir.exists(data))
  dir.create("data")

message("Find compilation data")

data_ready_dirs <- normalizePath(dirname(dir(TESTS_DIR, pattern = "DATA_READY", recursive=TRUE, full.names=TRUE)))

message("Merge compilation data from ", length(data_ready_dirs), " test runs.")

read_and_prepare <- function(d) {

  test_fname <- basename(d)
  test_fun <- basename(dirname(d))
  test_pkg <- basename(dirname(dirname(d)))

  # ID is a size_t and can be larger than R int type, so use a string
  classes <- c("character", "character", "character", "integer", "integer", "double")
  dt <- fread(file=file.path(d, "profile", "compile_stats.csv"), header=TRUE, colClasses=classes)
  dt <- data.table(test_pkg=test_pkg, test_fun=test_fun, test_fname=test_fname, dt)
  # update success into a boolean var
  dt[, SUCCESS := as.logical(SUCCESS)]
  dt
}

# Bind all csv.s together
df <- rbindlist(lapply(data_ready_dirs, read_and_prepare))

fwrite(df, file="data/cmp.csv")
saveRDS(df, file="data/cmp_dt.RDS", compress=FALSE)
saveRDS(as_tibble(df), file="data/cmp_tbl.RDS", compress=FALSE)

