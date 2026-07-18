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

predict_combinations <- function(
  pre_semester_gpa = ? numeric,
  major_category = ? character,
  year_of_study = ? character,
  institutional_policy = ? character,
  samples = ? integer
) {
   all_combinations <- cross_df(hypothesis_space)

   all_combinations_with_fix_cols <- all_combinations |>
      slice_sample(n = samples) |>
      mutate(
         Pre_Semester_GPA     = pre_semester_gpa,
         Major_Category       = major_category,
         Year_of_Study        = year_of_study,
         Institutional_Policy = institutional_policy
      )

   all_combinations_with_fix_cols |>
      mutate(
         Predicted_Post_Semester_GPA = round(predict(model_fit, new_data = all_combinations_with_fix_cols), 2)
      )
}

give_recommendations <- function(predicted_combinations) {
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
