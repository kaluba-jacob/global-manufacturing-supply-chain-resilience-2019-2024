# ==================================================
# Project: Global Manufacturing Supply Chain Resilience 2019-2024
# Script: 00_setup_environment.R
# Description: Install & load required packages, set project paths,
#              define helper functions for reproducible analysis.
# ==================================================

# 1. Install required packages (run once, skips already installed) ----
required_packages <- c(
  "tidyverse",    # Core data manipulation & visualization (dplyr, ggplot2, readr, etc.)
  "here",         # Project-relative file paths for reproducibility
  "readxl",       # Read Excel files (.xlsx)
  "writexl",      # Write Excel files
  "janitor",      # Clean column names & data
  "countrycode",  # Standardize country codes & names
  "scales",       # Format numbers & percentages in plots
  "corrplot",     # Correlation matrix visualization
  "stargazer"     # Export regression tables
)

new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages) > 0) {
  cat("Installing", length(new_packages), "new packages:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages, dependencies = TRUE)
} else {
  cat("All required packages already installed.\n")
}

# 2. Load all packages ----
invisible(lapply(required_packages, library, character.only = TRUE))
cat("All packages loaded successfully.\n\n")

# 3. Set project path constants ----
RAW_DATA_PATH       <- here("data", "raw")
PROCESSED_DATA_PATH <- here("data", "processed")
OUTPUT_PATH         <- here("output")
SCRIPTS_PATH        <- here("R-scripts")

# Create directories if they don't exist
dir.create(PROCESSED_DATA_PATH, showWarnings = FALSE, recursive = TRUE)
dir.create(OUTPUT_PATH, showWarnings = FALSE, recursive = TRUE)

# 4. Common helper functions ----

# Standardize column names to snake_case
clean_names <- function(df) {
  df %>% janitor::clean_names(case = "snake")
}

# Print dataset summary info (expects year & iso3 columns)
print_dataset_info <- function(df, df_name) {
  cat("=== Dataset:", df_name, "===\n")
  cat("  Dimensions:", dim(df)[1], "rows x", dim(df)[2], "columns\n")
  if ("year" %in% colnames(df)) {
    cat("  Time range:", min(df$year, na.rm = TRUE), "-", max(df$year, na.rm = TRUE), "\n")
  }
  if ("reporter_iso3" %in% colnames(df)) {
    cat("  Reporter countries:", n_distinct(df$reporter_iso3), "\n")
  }
  if ("iso3" %in% colnames(df)) {
    cat("  Countries:", n_distinct(df$iso3), "\n")
  }
  if ("sector_name" %in% colnames(df)) {
    cat("  Sectors:", n_distinct(df$sector_name), "\n")
  }
  cat("\n")
}

# Safe summary for numeric columns
safe_summary <- function(df) {
  df %>%
    select(where(is.numeric)) %>%
    summary() %>%
    print()
}

# 5. Environment confirmation ----
cat("========================================\n")
cat("  Environment setup complete\n")
cat("========================================\n")
cat("  Raw data path:       ", RAW_DATA_PATH, "\n")
cat("  Processed data path: ", PROCESSED_DATA_PATH, "\n")
cat("  Output path:         ", OUTPUT_PATH, "\n")
cat("========================================\n")
