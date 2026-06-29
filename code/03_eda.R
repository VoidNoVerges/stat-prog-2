# 03_eda.R
# Exploratory data analysis: distributions, missingness, relationships.
# Figures are saved to docs/ for inclusion in report.qmd.

library(tidyverse)
library(here)

data <- read_csv(here("data", "processed", "data_clean.csv"))

# Find out boundaries for ylim
print(summary(data))

# For question 1:
ai_usage_gpa_change <- ggplot(data, aes(x = Percentage_Of_AI_Usage, y = GPA_Change_Over_Semester)) +
  geom_point(aes(color = Percentage_Of_AI_Usage), size = 1, show.legend = FALSE) +
  scale_color_gradient(low = "gray80", high = "midnightblue") +
  geom_smooth(se = FALSE, color = "firebrick", size = 1.2) +
  xlim(0.0, 1.0) +
  ylim(-1.1, 1.1) +
  labs(
    title = "GPA change caused by gernative AI usage",
    x = "Generative AI usage percentage",
    y = "GPA change over the semester"
  ) +
  theme_minimal()

ggsave(here("docs", "eda_files", "ai_usage_gpa_change.png"), ai_usage_gpa_change)


ai_usage_gpa_change_by_majors <- ai_usage_gpa_change +
  # scales = "free_x" for enforcing visibility of x-scale
  facet_wrap(~Major_Category, ncol = 3, nrow = 2, scales = "free_x") +
  theme(panel.spacing = unit(1, "cm")) +
  labs(title = "GPA change caused by gernative AI usage faceted by majors")

ggsave(here("docs", "eda_files", "ai_usage_gpa_change_by_majors.png"), ai_usage_gpa_change_by_majors)
