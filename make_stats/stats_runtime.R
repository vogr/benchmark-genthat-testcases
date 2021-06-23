#!/usr/bin/env Rscript

library(data.table)
library(dplyr, warn.conflicts = FALSE)

library(tibble)
library(readr)
library(ggplot2)

load_data <- function() {
  message("Loading data...")
  readRDS("data/runtimes_med_tbl.RDS")
}

write_data <- function(x, dest) {
  fwrite(as.data.table(x), file=file.path("analysis", dest))
}


df <- load_data()


# Each file was run N times, one data point per iteration per run
#   file1, it1, t1_1
#   file1, it1, t1_2
#   file1, it1, t1_3
# avg over each it:
#   file1, it1, t1_avg
df <- df %>%
  group_by(test_pkg,test_fun,test_fname,lang,it) %>%
  summarise(runtime=mean(runtime))


# save this df for later use...
iteration_data <- df

# mark warmup iterations
df <- df %>% mutate(warmup = it <= 10)


hot_and_cold_stats <- function(data,key) {
  wt <- data %>% filter(warmup) %>% summarise(t=sum(runtime))
  ht <- data %>% filter(!warmup) %>% summarise(avg=mean(runtime), sd=sd(runtime))
  tibble(
    warmup_time = wt[["t"]],
    hot_it_avg = ht[["avg"]],
    hot_it_sd = ht[["sd"]]
  )
}

df <- df %>%
  group_by(test_pkg,test_fun,test_fname,lang) %>%
  group_modify(hot_and_cold_stats)


#TODO: Use a pivot_wider instead !
# from
#   file1 R   avg
#   file1 Rsh avg
# to
#   file1 avg.R avg.Rsh
df <- df %>%
      inner_join(
        x = filter(., lang == "bench-R"),
        y = filter(., lang == "bench-Rsh"),
        by=c("test_pkg","test_fun","test_fname"),
        suffix=c(".R",".Rsh")
      )
  
print("after join")
print(df)
glimpse(df)

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


# recover iteration data for top scorers, so that we can plot
df <- df %>%
  ungroup() %>%
  slice(1:10) %>%
  select(test_pkg,test_fun,test_fname,score)

print(df)
glimpse(df)

df <- df %>%
  inner_join(
    x = .,
    y = iteration_data,
    by=c("test_pkg","test_fun","test_fname")
  )

print(df)
glimpse(df)

i <- 0

make_plot_for_group <- function(data,key) {

	data <- data %>% select(-score)

	p <- ggplot(data=data) +
			scale_y_continuous(trans='log10') +
			geom_line(aes(x=it, y=runtime, color=lang))
			labs(x = "Iteration", y = "Runtime (ms)", color="R version") 
	output <- paste0("graphs/g", i, ".pdf")
	ggsave(output, plot=p)

	i <<- i + 1
}

# plot the top scorer
df %>% group_by(test_pkg,test_fun,test_fname) %>%
  group_walk(make_plot_for_group)
