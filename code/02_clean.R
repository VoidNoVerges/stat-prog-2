# 02_clean.R
# Reads raw data, applies cleaning steps, writes to data/processed/.

library(tidyverse)
library(here)

raw <- read_csv(here("data", "raw", "ai_student_impact_dataset (1).csv"))

"
Which columns to add/remove?


question 1: In which majors is the GPA most affected by heavier AI Usage?
The goal is to show in which majors which amount of AI usage is helps the GPA
in general, not how AI should be used (e.g. with Tool_Diversity). For that is
question 2.

Heaviness of AI Usage: This is best decribed by
\"Weekly_GenAI_Hours / Traditional_Study_Hours + Weekly_GenAI_Hours\"
as it measures to which percentage AI used to learn.
Note that this does not measure how much the students learned in general.

Effect: The effect can be 1. the GPA change over time (Pre_Semester_GPA vs
Post_Semester_GPA) or 2. how good the GPA of the students is in general
when using AI using the average of the Pre_Semester_GPA and the
Post_Semester_GPA.
But 2. is a pretty wonky indicator as it has many biases (e.g. students having a
different average GPA depending on the major). So we only use 1. as it actually
shows us the effects over time.

=> Add 2 new columns GPA_Change_Over_Semester and Percentage_Of_AI_Usage


question 2: How can AI be used for the best GPA score?

Another dimension to add is the Weekly_Study_Hours.
As we already have GPA_Change_Over_Semester the differentiation between
Traditional_Study_Hours and Weekly_GenAI_Hours is redundant and it is better
saved in Weekly_Study_Hours (Traditional_Study_Hours + Weekly_GenAI_Hours).
So the model tells you how much to learn and to which percentage use AI
which is easier to interprete than just Traditional_Study_Hours vs
Weekly_GenAI_Hours.
Traditional_Study_Hours and Weekly_GenAI_Hours should now be removed as they
just describe Percentage_Of_AI_Usage and Weekly_Study_Hours.

=> Add 1 new column Weekly_Study_Hours and remove 2 columns
   Traditional_Study_Hours and Weekly_GenAI_Hours


=> TO ADD: GPA_Change_Over_Semester, Percentage_Of_AI_Usage, Weekly_Study_Hours.
   TO REMOVE: Traditional_Study_Hours, Weekly_GenAI_Hours
"


"
The summary method has shown:
  - The column data types get all recognize and make sense.
  - The min/max values from summary all make sense.
  - There are no NA values.
"

round_3 <- function(x) {
  round(x, digits = 3)
}

cleaned <- raw |>
  # Every row (<=> student) is identified by a student ID (100001-150000) in the column Student_ID.
  # distinct is called to ensure there are no duplicate rows.
  distinct() |>
  # Remove unwanted whitespaces.
  mutate(across(where(is.character), stringr::str_squish)) |>
  # Add/remove columns mentioned above.
  mutate(
    GPA_Change_Over_Semester =
      (Pre_Semester_GPA - Post_Semester_GPA) |> round_3()
  ) |>
  mutate(
    Percentage_Of_AI_Usage =
      (Weekly_GenAI_Hours /
        (Traditional_Study_Hours + Weekly_GenAI_Hours)) |> round_3()
  ) |>
  mutate(
    Weekly_Study_Hours = (Traditional_Study_Hours +
      Weekly_GenAI_Hours) |> round_3()
  ) |>
  select(-c(Traditional_Study_Hours, Weekly_GenAI_Hours))

write_csv(cleaned, here("data", "processed", "data_clean.csv"))
message("Wrote data/processed/data_clean.csv")
