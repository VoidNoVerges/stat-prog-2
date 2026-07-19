"
For question 2:

As shown in the graphs in eda for question 1 the model needed for this
must be able to model non-linear relations (line is first flat, then goes up which
indicates non-linear relationship). This is the optimization problem in a nutshell:

Context variables:
Pre_Semester_GPA
Major_Category
Year_of_Study
Institutional_Policy

Target variable:
Post_Semester_GPA

Decision variables:
Weekly_Study_Hours
Percentage_Of_AI_Usage
Tool_Diversity
Primary_Use_Case
Paid_Subscription
Prompt_Engineering_Skill

The other variables are not used, as they are questionable in the way they were
inquired and the relationship to the context/decision variables.

=> The goal is given the context find the best combination of decision variables
   for the highest value of the target variable.
"

library(here)
library(tidyverse)
library(tidymodels)
library(bonsai)
library(lightgbm)
library(finetune)



build_model_fit <- function() {
   data <- read_csv(here("data", "processed", "data_clean.csv")) |>
      select(-c(
         Student_ID, Perceived_AI_Dependency, Anxiety_Level_During_Exams,
         Skill_Retention_Score, Burnout_Risk_Level, GPA_Change_Over_Semester
      ))

   recipe <- recipe(Post_Semester_GPA ~ ., data = data) |>
      step_mutate_at(all_logical_predictors(), fn = as.numeric) |>
      step_novel(all_nominal_predictors()) |>
      step_unknown(all_nominal_predictors()) |>
      step_integer(all_nominal_predictors())

   specification <- boost_tree() |>
      set_engine("lightgbm") |>
      set_mode("regression")

   model_fit <- workflow() |>
      add_recipe(recipe) |>
      add_model(specification) |>
      fit(data = data)
}

model_fit <- build_model_fit()

hypothesis_space <- list(
   Weekly_Study_Hours = seq(1, 40, by = 1),
   Percentage_Of_AI_Usage = seq(0.0, 1.0, by = 0.01),
   Tool_Diversity = 1:5,
   Primary_Use_Case = c(
      "Copywriting/Drafting", "Ideation", "Summarizing_Reading",
      "Debugging/Troubleshooting", "Direct_Answer_Generation"
   ),
   Paid_Subscription = c(TRUE, FALSE),
   Prompt_Engineering_Skill = c("Beginner", "Intermediate", "Advanced")
)

hypothesis_grid <- cross_df(hypothesis_space)

build_combinations <- function(pre_semester_gpa, major_category, year_of_study, institutional_policy, samples) {
   hypothesis_grid |>
      slice_sample(n = samples) |>
      mutate(
         Pre_Semester_GPA     = pre_semester_gpa,
         Major_Category       = major_category,
         Year_of_Study        = year_of_study,
         Institutional_Policy = institutional_policy
      )
}

give_recommendations <- function(built_combinations) {

   predicted_combinations <- built_combinations |>
      mutate(
         Predicted_Post_Semester_GPA = round(predict(model_fit, new_data = built_combinations), 2)
      )

   best_results <- predicted_combinations |>
      arrange(desc(Predicted_Post_Semester_GPA)) |>
      slice_head(n = 10)

   recommendations <- best_results |>
      select(
         Weekly_Study_Hours, Percentage_Of_AI_Usage, Tool_Diversity,
         Primary_Use_Case, Paid_Subscription, Prompt_Engineering_Skill,
         Predicted_Post_Semester_GPA
      )
}

clean_predictions <- function(predictions) {
   get_mode <- function(x) {
      if (all(is.na(x))) {
         return(NA_character_)
      }
      modes <- table(x, useNA = "no")
      names(modes)[which.max(modes)]
   }

   predictions |>
      group_by(Predicted_Post_Semester_GPA) |>
      summarise(
         across(where(is.numeric), mean, na.rm = TRUE),
         across(where(is.character), get_mode),
         .groups = "drop"
      )
}

major_categories <- c("STEM", "Medical", "Arts", "Business", "Humanities")
years_of_study <- c("Junior", "Senior", "Graduate", "Sophomore", "Freshman")
institutional_policies <- c("Strict_Ban", "Allowed_With_Citation", "Actively_Encouraged")
gpa_vector <- seq(from = 1.0, to = 4.0, by = 0.1)

total_iterations <- length(major_categories) *
   length(institutional_policies) *
   length(years_of_study)

current_iteration <- 1
start_time <- Sys.time()

calculate_df <- function(mc, ip, yos) {

   combinations <- bind_rows(lapply(gpa_vector, function(gpa) {
      build_combinations(gpa, mc, yos, ip, 50000)
   }))

   combinations <- combinations |>
      mutate(
         Predicted_Post_Semester_GPA = round(predict(model_fit, new_data = combinations), 2)
      )

   # group_split is used for ordering the Pre_Semester_GPA values.
   df <- bind_rows(lapply(group_split(combinations, Pre_Semester_GPA), clean_predictions))

   current_iteration <<- current_iteration + 1
   remaining_iterations <- total_iterations - current_iteration

   progress <- (current_iteration / total_iterations) * 100

   elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
   time_per_iteration <- elapsed_time / current_iteration
   remaining_time_secs <- time_per_iteration * remaining_iterations

   if (remaining_time_secs < 60) {
      time_string <- sprintf("%.1f Seconds", remaining_time_secs)
   } else if (remaining_time_secs < 3600) {
      time_string <- sprintf("%.1f Minutes", remaining_time_secs / 60)
   } else {
      time_string <- sprintf("%.2f Hours", remaining_time_secs / 3600)
   }

   cat(sprintf("Progress: %.2f%% | Remaining time: %s\n", progress, time_string))
   print(df)
}

for (mc in major_categories) {
   for (ip in institutional_policies) {
      for (yos in years_of_study) {
         calculate_df(mc, ip, yos)
      }
   }
}
