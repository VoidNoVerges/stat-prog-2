# 02_clean.R
# Reads raw data, applies cleaning steps, writes to data/processed/.

library(tidyverse)
library(here)

raw <- read_csv(here("data", "raw", "ai_student_impact_dataset (1).csv"))

cleaned <- raw |>
  # Ensure no duplicate student IDs.
  dplyr::distinct() |>
  # Remove unwanted whitespaces.
  dplyr::mutate(across(where(is.character), stringr::str_squish))

# The rest of the data is guaranteed to be clean as shown
# via the summary method in the proposal:
#   - The column data types get all recognize and make sense.
#   - The min/max values from summary all make sense.
#   - There are no NA values.

write_csv(cleaned, here("data", "processed", "data_clean.csv"))
message("Wrote data/processed/data_clean.csv")
