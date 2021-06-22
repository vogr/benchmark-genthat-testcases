#!/usr/bin/env Rscript


library(data.table)
#library(dtplyr)
library(dplyr, warn.conflicts = FALSE)

library(tibble)
library(readr)
library(ggplot2)


write_lazy <- function(x, dest) {
  # fwrite is much faster than write_csv
  fwrite(as.data.table(x), file=dest)
}


if (! dir.exists("analysis"))
  dir.create("analysis")



load_data <- function() {
  message("Reading data")
  dt <- readRDS("data/cmp_tbl.RDS")

  #dt <- readRDS("data/cmp_dt.RDS")
  #message("To lazy")
  #lazy_dt(dt)
  dt
}

df <- load_data()

#message("Successes and failures...")
#successes <- df %>% filter(SUCCESS == TRUE)
#failures <- df %>% filter(SUCCESS == FALSE)
#
#write_lazy(successes, "analysis/successes.csv")
#write_lazy(failures, "analysis/failures.csv")
#
#message("Failures cmp times")
#failures_cmp_time <- arrange(failures, desc(CMP_TIME))
#write_lazy(failures_cmp_time, "analysis/failure_cmp_time.csv")
#
#message("Cmp times")
#cmp_times <- arrange(df, desc(CMP_TIME))
#write_lazy(cmp_times, "analysis/cmp_times.csv")
#
#message("Main fun stats")
#main_fun <- df %>% filter(NAME == paste0(test_pkg, ":::", test_fun))
#write_lazy(main_fun, "analysis/main_fun.csv")


message("Recompilation")
recompilation <- df %>% filter(SUCCESS == TRUE) %>%
    group_by(test_pkg,test_fun,test_fname,ID,NAME,VERSION) %>%
    summarise(n_cmp=max(ID_CMP), avg_cmp_time=mean(CMP_TIME), max_cmp_time=max(CMP_TIME)) %>%
    arrange(desc(n_cmp), test_pkg, test_fun, test_fname)

write_lazy(recompilation, "analysis/recompilation.csv")



message("Versions")
versions <- df %>% group_by(NAME) %>%
             summarise(n_versions = length(unique(VERSION))) %>%
             arrange(desc(n_versions))
write_lazy(versions, "analysis/versions.csv")
