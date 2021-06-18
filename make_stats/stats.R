#!/usr/bin/env Rscript

library(tibble)
library(dplyr)
library(readr)
library(ggplot2)

df <- read_csv("all.csv", col_types="ccccccild")


successes <- df %>% filter(SUCCESS == TRUE)
failures <- df %>% filter(SUCCESS == FALSE)


write_csv(successes, "successes.csv")
write_csv(failures, "failures.csv")

write_csv(arrange(failures, desc(CMP_TIME)), "failure_desc.csv")

write_csv(arrange(df, desc(CMP_TIME)), "cmp_times.csv")

main_fun <- df %>% filter(NAME == paste0(test_pkg, ":::", test_fun))

write_csv(main_fun, "main_fun.csv")


recompilation <- df %>% filter(ID_CMP > 0 && SUCCESS == TRUE)
write_csv(recompilation, "recompilation.csv")
