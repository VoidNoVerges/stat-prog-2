# StatProg2 - A statistical programming exercise on student AI behaviour

This project revolves around understanding how students use AI and should use it for
a better grade.
The dataset captures many different relations of traditional learning and learning
with generative AI to the student's grades.
My overarching goal however is to get a better insight on statistical programming
and its workflows.

Find out more about the project guidelines: [LMU StatProg2 - Group Project Guidelines](https://soda-lmu.github.io/StatProg2-2026-SoSe/group-project-guidelines.html)

## Research Questions

1. In which majors is the GPA most affected by heavier AI Usage?
2. How can AI be used for the best GPA score?

## Dataset

- **Source:**
[Impact of AI on Students](https://www.kaggle.com/datasets/laveshjadon/ai-impact-on-students?select=ai_student_impact_dataset+%281%29.csv)
- **Licence:**
[CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
- **Description:**
The synthetic dataset "Impact of AI on Students" is about the generative AI usage of students and its effects on them.
It features 50000 simulated students with 16 features.
They capture various key information of the students (e.g. their major, study year & GPA score),
but also how they use generative AI (e.g. which tools they use, which usecase they have & their prompting skills).

## Group Members

| Name                     | GitHub username |
|--------------------------|-----------------|
| Paul Gustav Hoffmann     | VoidNoVerges    |

## Repository Structure

```
data/raw/        read-only raw data and licence documentation
data/processed/  cleaned data produced by code/02_clean.R
code/            numbered R scripts (01 download → 02 clean → 03 EDA → 04 analysis)
docs/            rendered Quarto website output (auto-generated, do not edit)
proposal.qmd     W07 project proposal
report.qmd       final analysis report
```

## How to reproduce

```r
# 1. Install dependencies
renv::restore()   # if using renv, otherwise install packages manually

# 2. Donwload the dataset
# There are multiple different ways (look up the source of the dataset).
# However I recommend following the instructions in code/01_download.py

# 3. Run the pipeline in order
source("code/02_clean.R")
source("code/03_eda.R")
source("code/04_analysis.R")

# 4. Render the website
quarto::quarto_render()
```
