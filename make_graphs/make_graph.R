#!/usr/bin/env Rscript

library(dplyr)
library(ggplot2)
library(purrr)
library(tibble)

N_BENCHMARKS=20

argv <- commandArgs(trailingOnly=TRUE)

if (length(argv) < 2) {
  message("Two arguments required: directory and output")
  exit(1)
}

base_directory <- argv[[1]]
output <- argv[[2]]

R_dir <- normalizePath(file.path(base_directory, "bench-R"))
Rsh_dir <- normalizePath(file.path(base_directory, "bench-Rsh"))
rir_dir <- normalizePath(file.path(base_directory, "bench-rir"))


process_dir <- function(dir) {
  l <- list()
  for (i in 1:N_BENCHMARKS) {
    fname <- normalizePath(paste0(dir, "/bench-", i, ".RDS"))
    
    row_name <- paste0("run", i)
    # as ms
    l[[row_name]] <- readRDS(fname) * 1000
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
  runtime_rir=process_dir(rir_dir),
  it=1:length(runtime_R),
)

p <- ggplot(df, aes(x = it)) +
     scale_y_continuous(trans='log10') +
     geom_line(aes(y=runtime_R, color="GNU R")) + geom_point(aes(y=runtime_R, color="GNU R")) +
     geom_line(aes(y=runtime_Rsh, color="Rsh")) + geom_point(aes(y=runtime_Rsh, color="Rsh")) +
     geom_line(aes(y=runtime_rir, color="rir")) + geom_point(aes(y=runtime_rir, color="rir")) +
     #geom_col(aes(y=runtime_R, color="steelblue")) +
     #geom_col(aes(y=runtime_Rsh, color="darkred")) +
     labs(x = "Iteration", y = "Runtime (ms)", color="R version", title=base_directory)

ggsave(output, plot=p)
