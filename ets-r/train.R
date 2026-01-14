# List packages
library(tidyverse)
library(fable)
library(tsibble)

# train models - # auto ets model 

train_chap <- function(csv_fn, model_fn) {
  df <- read_csv(csv_fn) |> 
    mutate(target = if_else(is.na(target), 0, target),
           time_period = yearmonth(time_period))
  
  df <- df |> distinct() |> 
    as_tsibble(index = time_period, key = location) |> 
    fill_gaps(target=0L, .full = TRUE)
  
  model <- df |> 
    model(ets = ETS(target))
  
  saveRDS(model, file=model_fn)
  
  print('train done')
  
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 2) {
  csv_fn <- args[1]
  model_fn <- args[2]
  
  train_chap(csv_fn, model_fn)
}# else {
#  stop("Usage: Rscript train.R <csv_fn> <model_fn>")
#}
