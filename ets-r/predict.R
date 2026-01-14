# Load required libraries
library(tidyverse)
library(fable)
library(tsibble)

# Define the predict function
predict_chap <- function(model_fn, historic_data_fn, future_climatedata_fn, predictions_fn) {
  
  # Load the pre-trained model structure
  model <- readRDS(model_fn)
  
  print('read model')
  
  # Load the complete historical data
  historic_df <- read_csv(historic_data_fn) |>
    mutate(target = if_else(is.na(target), 0, target),
           time_period = yearmonth(time_period)) |>
    as_tsibble(index = time_period, key = location) |> 
    fill_gaps(target=0L, .full = TRUE) 
  
  # Load the future data (covariates only)
  future_df <- read_csv(future_climatedata_fn) |>
    mutate(time_period = yearmonth(time_period)) |>
    as_tsibble(index = time_period, key = location)
  
  print('load_data')
  
  # Refit the model with all historic data and forecast
  
  model <- model |>
    refit(historic_df)
  
  y_pred <- model |>
    generate(new_data = future_df, bootstrap = FALSE, times = 1000) |> 
    mutate(.rep = as.integer(.rep)) |> 
    arrange(.rep) |> 
    pivot_wider(names_from = .rep, values_from = .sim, names_prefix = "sample_")
  
  print(y_pred)
  
  # saveRDS(model, file = model_fn)
  
  df_out <- future_df |>
    left_join(y_pred |>
                select(-.model) |> 
                mutate(across(starts_with("sample_"), ~ if_else(. < 0, 0, .))) |>
                rename_with(~ paste0("sample_", as.integer(str_extract(., "\\d+")) - 1), starts_with("sample_")),
              by = c('location', 'time_period')
    ) |>
    as_tibble() |>
    mutate(time_period = format(as.Date(time_period), "%Y-%m")) |> 
    select(time_period, location, starts_with("sample_"))
  
  
  print('made predictions')
  
  df_out |> print()
  
  
  write.csv(df_out, predictions_fn, row.names = FALSE)
  
  fname <- paste0("df_out_", format(Sys.time(), "%Y%m%d_%H%M%S"), predictions_fn)
  write_csv(y_pred, fname)
  
}

# --- Command Line Argument Handling (No change here) ---

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 4) {
  model_fn <- args[1]
  historic_data_fn <- args[2]
  future_climatedata_fn <- args[3]
  predictions_fn <- args[4]
  
  predict_chap(model_fn, historic_data_fn, future_climatedata_fn, predictions_fn)
}

# Inventory sim

source('quantile_based_inventory_sim.R')


