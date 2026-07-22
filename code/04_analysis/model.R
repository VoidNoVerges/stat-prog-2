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


get_dataset <- function() {
   data <- read_csv(here("data", "processed", "data_clean.csv")) |>
      select(-c(
         Student_ID, Perceived_AI_Dependency, Anxiety_Level_During_Exams,
         Skill_Retention_Score, Burnout_Risk_Level, GPA_Change_Over_Semester
      ))
}

build_model_fit <- function(data) {

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

validate_model_fit <- function() {
   split <- initial_split(get_dataset(), prop = 0.8)
   train_data <- training(split)
   test_data  <- testing(split)

   model_fit <- build_model_fit(train_data)

   predictions <- test_data |>
      mutate(.pred = predict(model_fit, new_data = test_data)$.pred)

   model_metrics <- predictions |>
      metrics(truth = Post_Semester_GPA, estimate = .pred)

   baseline_metrics <- predictions |>
      metrics(truth = Post_Semester_GPA, estimate = Pre_Semester_GPA)
   
   list(Model_Metrics=model_metrics, Baseline_Metrics=baseline_metrics)
}

model_fit <- build_model_fit(get_dataset())

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

get_feature_importance <- function(model_fit) {
   booster <- extract_fit_engine(model_fit)

   importance <- as_tibble(lgb.importance(booster, percentage = TRUE)) |>
      arrange(desc(Gain))

   importance
}

give_recommendations <- function(built_combinations) {
   predicted_combinations <- built_combinations |>
      mutate(
         Predicted_Post_Semester_GPA = round(predict(model_fit, new_data = built_combinations)$.pred, 2)
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