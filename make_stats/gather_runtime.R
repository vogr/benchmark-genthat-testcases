#!/usr/bin/env Rscript

# fread and fwrite are faster than their equivalent in readr
# data.table::rbindlist is faster than tibble::bind_rows
# This makes data.table a much better fit for this simple task


library(data.table)
library(tibble)

TESTS_DIR <- "../runtests/tests"
#TESTS_DIR <- "devel"

if (!dir.exists("data"))
  dir.create("data")

message("Find data dirs...")

data_ready_dirs <- normalizePath(dirname(dir(TESTS_DIR, pattern = "DATA_READY", recursive=TRUE, full.names=TRUE)))

message("Merge runtime data from ", length(data_ready_dirs), " test runs.")

read_and_prepare <- function(d) {
  test_fname <- basename(d)
  test_fun <- basename(dirname(d))
  test_pkg <- basename(dirname(dirname(d)))

  test_id <- list(test_pkg=test_pkg, test_fun=test_fun, test_fname=test_fname)

  benches <- dir(d, pattern="bench-.*\\.RDS", recursive=TRUE, full.names=TRUE)

  rows <- vector("list", length=length(benches))
  for(i in seq_along(benches)) {
    b <- benches[[i]]
    bench <- basename(b)
    lang <- basename(dirname(b))
    bench_id <- list(bench=bench, lang=lang)
    
    times <- readRDS(b)

    rows[[i]] <- c(test_id, bench_id, times)
  }
  rows
}

# Bind all csv.s together
all_rows <- lapply(data_ready_dirs, read_and_prepare)
all_rows_dt <- lapply(all_rows, function(x) rbindlist(x, fill=TRUE))
df <- rbindlist(all_rows_dt, fill=TRUE)

fwrite(df, file="data/runtimes.csv")
#saveRDS(df, file="data/all_dt.RDS", compress=FALSE)
#saveRDS(as_tibble(df), file="data/all_tbl.RDS", compress=FALSE)

