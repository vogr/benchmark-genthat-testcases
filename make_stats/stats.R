#!/usr/bin/env Rscript


library(data.table)
library(dtplyr)
library(dplyr, warn.conflicts = FALSE)

library(tibble)
library(readr)
library(ggplot2)

dt <- readRDS("all.RDS")
df <- lazy_dt(dt)

successes <- df %>% filter(SUCCESS == TRUE)
failures <- df %>% filter(SUCCESS == FALSE)


write_csv(as.data.table(successes), "successes.csv")
write_csv(as.data.table(failures), "failures.csv")

write_csv(as.data.table(arrange(failures, desc(CMP_TIME))), "failure_cmp_time.csv")

write_csv(as.data.table(arrange(df, desc(CMP_TIME))), "cmp_times.csv")

main_fun <- df %>% filter(NAME == paste0(test_pkg, ":::", test_fun))
  %>% as.data.table()

write_csv(main_fun, "main_fun.csv")


recompilation <- df %>% filter(ID_CMP > 1 & SUCCESS == TRUE) %>%
  arrange(desc(ID_CMP), test_pkg, test_fun, test_fname) %>%
  as.data.table()

write_csv(recompilation, "recompilation.csv")


# How many different versions?

versions <- df %>% group_by(NAME) %>%
             summarise(n_versions = length(unique(VERSION))) %>%
             arrange(desc(n_versions))
           %>% as.data.table()
write_csv(versions, "versions.csv")
