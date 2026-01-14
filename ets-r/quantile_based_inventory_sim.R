# Inventory simulation

library(tidyverse)
library(tsibble)
library(doParallel)

set.seed(100)

# Read data ---------------------------------------------------------------

actual_df <- read.csv('data/laos/laos_epi_cleaned.csv') |> 
  rename(date = time_period,
         dispensed = disease_cases) |> 
  select(date, location, dispensed) |> 
  as_tibble()

pred_all <- read.csv('predictions.csv')

pred_master_df <- pred_all |> 
  rename(date = time_period) |> 
  mutate(across(starts_with("sample"), ~ pmax(., 0))) |> 
  rowwise() |> 
  mutate(
    mean = mean(c_across(starts_with("sample")), na.rm = TRUE) * 3,
    q80  = quantile(c_across(starts_with("sample")), probs = 0.80, na.rm = TRUE, names = FALSE),
    q85  = quantile(c_across(starts_with("sample")), probs = 0.85, na.rm = TRUE, names = FALSE),
    q90  = quantile(c_across(starts_with("sample")), probs = 0.90, na.rm = TRUE, names = FALSE),
    q95  = quantile(c_across(starts_with("sample")), probs = 0.95, na.rm = TRUE, names = FALSE),
    q975 = quantile(c_across(starts_with("sample")), probs = 0.975, na.rm = TRUE, names = FALSE)
  )  |> 
  ungroup() |> 
  select(date, location, mean, q80, q85, q90, q95, q975)

master_df <- pred_master_df |> 
  left_join(actual_df, by = c('date', 'location')) |> 
  mutate(date = as.Date(paste0(date, "-01")))

# Inventory function ------------------------------------------------------

master_long <- master_df |> 
  # filter(location == '0701larmany-0701 Xamnua-BCG diluent' & model == 'ETS') |> 
  pivot_longer(cols = c('mean', 'q80', 'q85', 'q90', 'q95', 'q975'), names_to = 'target_csl', values_to = 'quantity') |> 
  mutate(id = paste0(location, ':', target_csl))

id_list <- master_long |> 
  pull(id) |> 
  unique() 

# Register outer parallel backend with multiple cores

n_cores <- detectCores(logical = FALSE) - 1   # 16 physical cores – 1 = 15
cl_outer <- makeCluster(n_cores)
registerDoParallel(cl_outer)

# parallel loop

system.time(inventory_sim_full <- foreach(i = id_list,
                                          .combine = 'rbind',
                                          .packages=c("doParallel", "foreach", "tidyverse", "tsibble", "fable")) %dopar% {
                                            
                                            # i <- id_list[1]
                                            
                                            df <- master_long |>
                                              filter(id == i) |> 
                                              group_by(location, target_csl) |> 
                                              arrange(date) |>
                                              mutate(
                                                target_stock = quantity,
                                                opening_stock = 0,
                                                received = 0,
                                                closing_stock = 0,
                                                order_qty = 0,
                                                delivery_due = NA,
                                                fixed_lead_time = 1
                                              )
                                            
                                            deliveries <- list()
                                            
                                            for (i in seq_len(nrow(df))) {
                                              today <- df$date[i]
                                              
                                              # Receive orders
                                              arrivals <- deliveries |>
                                                keep(~.x$arrival_date == today) |>
                                                map_dbl("amount") |>
                                                sum()
                                              
                                              df$opening_stock[i] <- if (i == 1) arrivals else df$closing_stock[i - 1] + arrivals
                                              actual <- df$dispensed[i]
                                              
                                              df$received[i] <- arrivals
                                              df$closing_stock[i] <- max(0, df$opening_stock[i] - actual)
                                              
                                              # Place order
                                              order_qty <- max(0, df$target_stock[i] - df$closing_stock[i])
                                              lead_time <- df$fixed_lead_time[i]
                                              delivery_date <- today %m+% months(lead_time)
                                              
                                              deliveries <- append(deliveries, list(list(arrival_date = delivery_date, amount = order_qty)))
                                              
                                              df$order_qty[i] <- order_qty
                                              df$delivery_due[i] <- delivery_date
                                            }
                                            
                                            
                                            inventory_sim <- df |>
                                              mutate(
                                                lost_sales = pmax(0, dispensed - pmin(dispensed, opening_stock)),
                                                met_demand = dispensed <= opening_stock,
                                                stockout = dispensed > opening_stock
                                              )
                                            
                                            inventory_sim
                                            
                                          })

# Stop outer cluster

stopCluster(cl_outer)


# Final data

write_csv(inventory_sim_full, 'inventory_sim.csv')


# Inventory value added ---------------------------------------------------

inv_metrics <- inventory_sim_full |> 
  group_by(location, target_csl) |> 
  slice(-1) |> 
  summarise(
    CSL = round(mean(met_demand, na.rm=TRUE), 1),
    stockout_rate = round(mean(stockout, na.rm=TRUE), 1),
    avg_inventory = round(mean(mean((opening_stock+closing_stock)/2, na.rm=TRUE), 1)),
    # avg_inventory = round(mean(if_else(order_qty >= 0.1,
    #                                     ((opening_stock+closing_stock)/2)/order_qty, NA_real_), 
    #                             na.rm=TRUE), 1),
    .groups        = "drop"
  )

fname <- paste0("df_out_", format(Sys.time(), "%Y%m%d_%H%M%S"), 'inventory.csv')
write_csv(inv_metrics, fname)
