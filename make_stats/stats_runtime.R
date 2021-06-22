#!/usr/bin/env Rscript

library(data.table)
library(dplyr, warn.conflicts = FALSE)

library(tibble)
library(readr)
library(ggplot2)

load_data <- function() {
  message("Loading data...")
  readRDS("data/runtimes_tbl.RDS") %>% slice(1:20)
}

write_data <- function(x, dest) {
  fwrite(as.data.table(x), file=file.path("analysis", dest))
}


df <- load_data()


it_cols <- sprintf("V%d", 1:50)

# Each file was run N times
#   file1, it1, it2, it3
#   file1, it1, it2, it3
#   file1, it1, it2, it3
# avg over each it:
#   file1, it1_avg, it2_avg, it3_avg
df <- df %>%
  group_by(test_pkg,test_fun,test_fname,lang) %>%
  summarise(across(all_of(it_cols), mean))



# save this df for later use...
iteration_data <- df

warmup_c <- sprintf("V%d", 1:10)
hot_c <- sprintf("V%d", 11:50)

df <- df %>%
  rowwise() %>%
  mutate(
    warmup_time = sum(c_across(all_of(warmup_c))),
    hot_it_avg = mean(c_across(all_of(hot_c))),
    hot_it_sd = sd(c_across(all_of(hot_c)))
  )

# drop all the iterations times, keep aggregate values
df <- df %>%
  select(test_pkg,test_fun,test_fname,lang,warmup_time,hot_it_avg,hot_it_sd)



# from
#   file1 R   avg
#   file1 Rsh avg
# to
#   file1 avg.R avg.Rsh
df <- df %>%
      inner_join(
        x = filter(., lang == "bench-R") %>% select(-lang),
        y = filter(., lang == "bench-Rsh") %>% select(-lang),
        by=c("test_pkg","test_fun","test_fname"),
        suffix=c(".R",".Rsh")
      )
  

df <- df %>%
  mutate(
    wr = warmup_time.Rsh / warmup_time.R,
    ir = hot_it_avg.Rsh / hot_it_avg.R,
    sr = hot_it_sd.Rsh / hot_it_sd.R,
    oh = warmup_time.Rsh / hot_it_avg.Rsh,
    score = max(1,wr) / 10 + max(1,ir) + max(1,sr) + oh/1000
    ) %>%
  relocate(score,wr,ir,sr,oh,.after=test_fname) %>%
  arrange(desc(score))

print(df)

glimpse(df)


write_data(df, "runtime_outlier_score.csv")


# recover iteration data for top scorers, so that we can plot
df <- df %>% slice(1:3) %>% select(test_pkg,test_fun,test_fname) %>%
  inner_join(
    x = .,
    y = iteration_data,
    by=c("test_pkg","test_fun","test_fname")
  )

print(df)
glimpse(df)


message("Plot!")

# plot the top scorer
df %>% group_by(test_pkg,test_fun,test_fname,lang) %>%
  group_map(function(x,y) { print(x) })
