#!/usr/bin/env Rscript

# fread and fwrite are faster than their equivalent in readr
# data.table::rbindlist is faster than tibble::bind_rows
# This makes data.table a much better fit for this simple task


library(data.table)
library(tibble)

TESTS_DIR <- "../runtests/tests"

if (!dir.exists("data"))
  dir.create("data")

message("Find data dirs")

data_ready_dirs <- normalizePath(dirname(dir(TESTS_DIR, pattern = "DATA_READY", recursive=TRUE, full.names=TRUE)))

message("Merge compilation data from ", length(data_ready_dirs), " test runs.")

read_and_prepare <- function(d) {

  test_fname <- basename(d)
  test_fun <- basename(dirname(d))
  test_pkg <- basename(dirname(dirname(d)))

  # ID is a size_t and can be larger than R int type, so use a string
  classes <- c("character", "character", "character", "integer", "integer", "double")
  dt <- fread(file=file.path(d, "profile", "compile_stats.csv"), header=TRUE, colClasses=classes)
  dt[, SUCCESS := as.logical(SUCCESS)]

  dt <- data.table(test_pkg=test_pkg, test_fun=test_fun, test_fname=test_fname, dt)
  # update success into a boolean var
  dt
}

# Bind all csv.s together
df <- rbindlist(lapply(data_ready_dirs, read_and_prepare))


write_all <- function(df, dest) {
  message("Write ", dest, " to disk")
  message("   + csv")
  fwrite(df, file=paste0("data/", dest, ".csv"))
  message("   + data.table")
  saveRDS(df, file=paste0("data/",dest,"_dt.RDS"), compress=FALSE)
  message("   + tibble")
  saveRDS(as_tibble(df), file=paste0("data/", dest, "_tbl.RDS"), compress=FALSE)
}


write_all(df, "cmp")
write_all(df[1:2000], "cmp_small")
write_all(df[1:100000], "cmp_med")

