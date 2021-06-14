#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(purrr)
library(tibble)

N_BENCHMARKS=100


argv <- commandArgs(trailingOnly=TRUE)

if (length(argv) < 2) {
  message("Two arguments required: directory and output")
  exit(1)
}

base_directory <- argv[[1]]
output <- argv[[2]]

R_dir <- normalizePath(paste0(base_directory, "/bench-R"))
Rsh_dir <- normalizePath(paste0(base_directory, "/bench-Rsh"))


process_dir <- function(dir) {
  l <- list()
  for (i in 1:N_BENCHMARKS) {
    fname <- normalizePath(paste0(dir, "/bench-", i, ".RDS"))
    
    row_name <- paste0("run", i)
    # as ms
    l[[row_name]] <- readRDS(fname) / 1000
  }


  # concatenate the rows as a matrix
  m1 <- do.call(rbind, l)

  #add column names
  col_names = sprintf("it%d", 1:50)
  colnames(m1) <- col_names

  df <- as_tibble(m1)

  means <- summarise_all(df, mean)

  # Extract first row as double vector
  v <- as.numeric(means[1,])
  v
}


df <- tibble(
  runtime_R=process_dir(R_dir),
  runtime_Rsh=process_dir(Rsh_dir),
  it=1:length(runtime_R),
)

p <- ggplot(df, aes(x = it)) +
     geom_line(aes(y=runtime_R, color="steelblue")) +
     geom_line(aes(y=runtime_Rsh, color="darkred")) +
     labs(x = "Iteration", y = "Runtime (ms)") +
     scale_y_continuous(trans='log10')

ggsave(output, plot=p)
