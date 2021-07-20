#!/usr/bin/env Rscript

# fread and fwrite are faster than their equivalent in readr
# data.table::rbindlist is faster than tibble::bind_rows
# This makes data.table a much better fit for this simple task



library(data.table)
library(DBI)

con <- dbConnect(RPostgres::Postgres(), host="172.17.0.2", port=5432, user="postgres", password="RProfiler",dbname="postgres")

TABLE <- "runtimes"

TESTS_DIR <- "/app/runtests/tests"


message("Find data dirs...")

t0 <- Sys.time()
data_ready_dirs <- normalizePath(dirname(dir(TESTS_DIR, pattern = "DATA_READY", recursive=TRUE, full.names=TRUE)))

message("Done in ", Sys.time() - t0)

data_ready_dirs <- data_ready_dirs[1:10000]


read_and_prepare <- function(d) {
  message("Process ", d)
  test_fname <- basename(d)
  test_fun <- basename(dirname(d))
  test_pkg <- basename(dirname(dirname(d)))

  test_id <- list(test_pkg=test_pkg, test_fun=test_fun, test_fname=test_fname)

  benches <- dir(d, pattern="bench-.*\\.RDS", recursive=TRUE, full.names=TRUE)

  rows <- vector("list", length=length(benches))
  for(i in seq_along(benches)) {
    b <- benches[[i]]
    bench <- basename(b)
    # drop the "bench-" in front
    lang <- substring(basename(dirname(b)), 7)
    bench_id <- list(lang=lang, bench=bench)
    
    times <- readRDS(b)

    l <- c(test_id, bench_id, list(it=seq_along(times), runtime=times))

    # rbindlist will convert l to a data.table, no need to do it explicitly now 
    rows[[i]] <- l
  }

  rows
}

message("Merge runtime data from ", length(data_ready_dirs), " test runs.")

t0 <- Sys.time()

df <- rbindlist(do.call(c, lapply(data_ready_dirs, read_and_prepare)))

message("Done in ", Sys.time() - t0)

if(dbExistsTable(con, TABLE)) {
  message("Drop existing table")
  dbRemoveTable(con, TABLE)
}
message("Add rows to database")
t0 <- Sys.time()
dbCreateTable(con, TABLE, df)

# VERY SLOW
#dbAppendTable(con, TABLE, df)

# SLOW
#dbWriteTable(con, TABLE, df, overwrite=TRUE)

res <- DBI::dbSendQuery(con, DBI::sqlAppendTable(con, TABLE, df, row.names=FALSE))
DBI::dbClearResult(res)


message("Done in ", Sys.time() - t0)

message("Done, disconnecting")
dbDisconnect(con)
