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
    bench_id <- list(lang=lang, bench=bench)
    
    times <- readRDS(b)

    l <- c(test_id, bench_id, list(it=seq_along(times), runtime=times))

    # rbindlist will convert l to a data.table, no need to do it explicitly now 
    rows[[i]] <- l
  }
  rbindlist(rows)
}

# Bind all csv.s together
df <- rbindlist(lapply(data_ready_dirs, read_and_prepare), fill=TRUE)

write_all <- function(df, dest) {
  message("Write ", dest, " to disk")
  message("   + csv")
  fwrite(df, file=paste0("data/", dest, ".csv"))
  message("   + data.table")
  saveRDS(df, file=paste0("data/",dest,"_dt.RDS"), compress=FALSE)
  message("   + tibble")
  saveRDS(as_tibble(df), file=paste0("data/", dest, "_tbl.RDS"), compress=FALSE)
}


write_all(df, "runtimes")
write_all(df[1:2000], "runtimes_small")
write_all(df[1:100000], "runtimes_med")
