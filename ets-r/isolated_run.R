source("ets-r/train.R")
source("ets-r/predict.R")

train_chap("ets-r/training_data.csv", 
           "ets-r/output/model.bin")

predict_chap("ets-r/output/model.bin", 
             "ets-r/historic_data.csv", 
             "ets-r/future_data.csv", 
             "ets-r/predictions.csv")

