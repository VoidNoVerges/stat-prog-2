library(here)
library(tidyverse)
library(patchwork)

source("code/04_analysis/model.R")



major_categories <- c("STEM", "Medical", "Arts", "Business", "Humanities")
years_of_study <- c("Junior", "Senior", "Graduate", "Sophomore", "Freshman")
institutional_policies <- c("Strict_Ban", "Allowed_With_Citation", "Actively_Encouraged")
gpa_vector <- seq(from = 1.0, to = 4.0, by = 0.1)

start_time <- Sys.time()
current_iteration <- 0
total_iterations <- length(major_categories) *
   length(institutional_policies) *
   length(years_of_study)

print_progress_time <- function() {
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
}

collapse_df <- function(predictions) {
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
         across(where(is.character) | where(is.logical), get_mode),
         .groups = "drop"
      )
}

calculate_df <- function(mc, ip, yos) {
   combinations <- bind_rows(lapply(gpa_vector, function(gpa) {
      build_combinations(gpa, mc, yos, ip, 50000)
   }))

   combinations <- combinations |>
      mutate(
         Predicted_Post_Semester_GPA = round(predict(model_fit, new_data = combinations)$.pred, 2)
      )

   # group_split is used for ordering the Pre_Semester_GPA values.
   df <- bind_rows(lapply(group_split(combinations, Pre_Semester_GPA), collapse_df))

   print_progress_time()

   df
}

plot_data <- bind_rows(lapply(major_categories, function(mc) {
   bind_rows(lapply(institutional_policies, function(ip) {
      bind_rows(lapply(years_of_study, function(yos) {
         calculate_df(mc, ip, yos)
      }))
   }))
}))

z_variables <- tribble(
   ~variable,                  ~label,                     ~type,
   "Weekly_Study_Hours",       "Weekly study hours",       "numeric",
   "Percentage_Of_AI_Usage",   "AI usage (%)",             "numeric",
   "Tool_Diversity",           "Tool diversity",           "numeric",
   "Primary_Use_Case",         "Primary use case",         "categorical",
   "Paid_Subscription",        "Paid subscription",        "logical",
   "Prompt_Engineering_Skill", "Prompt engineering skill", "categorical"
)

clean_facet_label <- function(x) str_replace_all(x, "_", " ")

build_z_plot <- function(z_var, z_label, z_type) {
   plot <- ggplot(plot_data, aes(x = Pre_Semester_GPA, y = Predicted_Post_Semester_GPA, color = .data[[z_var]])) +
      geom_point(size = 0.5, alpha = 0.7) +
      facet_grid(
         rows = vars(Major_Category),
         cols = vars(Institutional_Policy, Year_of_Study),
         labeller = labeller(
            Major_Category = clean_facet_label,
            Institutional_Policy = clean_facet_label,
            Year_of_Study = clean_facet_label
         )
      ) +
      labs(title = z_label, x = NULL, y = NULL, color = NULL) +
      theme_minimal(base_size = 7) +
      theme(
         strip.text = element_text(size = 5),
         plot.title = element_text(size = 10, face = "bold"),
         legend.key.height = unit(8, "pt"),
         legend.key.width = unit(10, "pt")
      )

   if (z_type == "numeric") {
      plot <- plot + scale_color_viridis_c()
   } else {
      plot <- plot + scale_color_viridis_d()
   }

   plot
}

z_plots <- pmap(z_variables, function(variable, label, type) {
   build_z_plot(variable, label, type)
})

combined_plot <- wrap_plots(z_plots, ncol = 1)

panel_width_in <- 1.1
panel_height_in <- 0.9
n_cols <- 15
n_rows_per_block <- 5
n_blocks <- nrow(z_variables)

ggsave(
   filename = here("docs", "analysis_files", "model_analysis.png"),
   plot = combined_plot,
   width = n_cols * panel_width_in + 1,
   height = n_blocks * (n_rows_per_block * panel_height_in + 0.6),
   dpi = 200,
   limitsize = FALSE
)
