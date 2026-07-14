# StatProg2 - A statistical programming exercise on student AI behaviour

This project revolves around understanding how students use AI and should use it for
a better grade.
The dataset captures many different relations of traditional learning and learning
with generative AI to the student's grades.
My overarching goal however is to get a better insight on statistical programming
and its workflows.

## Research Questions

1. In which majors is the GPA most affected by heavier AI Usage?
2. How can AI be used for the best GPA score?

## Dataset

- **Source:** <!-- URL or citation -->
- **Licence:** <!-- e.g. CC BY 4.0 -->
- **Description:** <!-- What does the data contain? What are the key variables? -->

## Group Members

| Name | GitHub username |
|------|----------------|
|      |                |
|      |                |
|      |                |

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

# 2. Run the pipeline in order
source("code/01_download.R")
source("code/02_clean.R")
source("code/03_eda.R")
source("code/04_analysis.R")

# 3. Render the website
quarto::quarto_render()
```
