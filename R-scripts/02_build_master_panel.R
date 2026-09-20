# ==================================================
# Project: Global Manufacturing Supply Chain Resilience 2019-2024
# Script: 02_build_master_panel.R
# Description: Reconstruct the full master panel from exported component
#              CSVs. Calculate supply chain concentration indicators (HHI,
#              CR3, Top3 shares) and merge with TiVA, LPI, and distance.
#              Memory-efficient: processes data step by step.
# ==================================================

# Run environment setup first
source(here("R-scripts", "00_setup_environment.R"))

cat("========== BUILDING MASTER PANEL ==========\n\n")

# --------------------------------------------------
# 1. Load component tables from CSV
# --------------------------------------------------
cat("Step 1: Loading component tables...\n")

# Comtrade (largest table - load with column type specification for efficiency)
df_comtrade <- read_csv(
  here(PROCESSED_DATA_PATH, "comtrade_bilateral_trade.csv"),
  col_types = cols(
    reporter_iso3 = col_character(),
    reporter_name = col_character(),
    partner_iso3 = col_character(),
    partner_name = col_character(),
    year = col_integer(),
    product_code = col_character(),
    hs_range = col_character(),
    sector_name = col_character(),
    flow = col_character(),
    value_kusd = col_double(),
    share = col_double()
  ),
  show_col_types = FALSE
)
cat("  Comtrade:", nrow(df_comtrade), "rows x", ncol(df_comtrade), "cols\n")

# TiVA GVC indicators - deduplicate by iso3 & year (keep rows with most data)
df_tiva <- read_csv(here(PROCESSED_DATA_PATH, "tiva_gvc_indicators.csv"), show_col_types = FALSE)
tiva_dupes <- sum(duplicated(df_tiva[, c("iso3", "year")]))
if (tiva_dupes > 0) {
  cat("  TiVA: found", tiva_dupes, "duplicate iso3-year rows, deduplicating...\n")
  df_tiva <- df_tiva %>%
    group_by(iso3, year) %>%
    arrange(desc(rowSums(!is.na(pick(everything())))), .by_group = TRUE) %>%
    slice(1) %>%
    ungroup()
}
cat("  TiVA:", nrow(df_tiva), "rows x", ncol(df_tiva), "cols\n")

# LPI logistics performance - deduplicate by iso3 & year (keep rows with most data)
df_lpi <- read_csv(here(PROCESSED_DATA_PATH, "lpi_logistics_performance.csv"), show_col_types = FALSE)
lpi_dupes <- sum(duplicated(df_lpi[, c("iso3", "year")]))
if (lpi_dupes > 0) {
  cat("  LPI: found", lpi_dupes, "duplicate iso3-year rows, deduplicating...\n")
  df_lpi <- df_lpi %>%
    group_by(iso3, year) %>%
    arrange(desc(rowSums(!is.na(pick(everything())))), .by_group = TRUE) %>%
    slice(1) %>%
    ungroup()
}
cat("  LPI:", nrow(df_lpi), "rows x", ncol(df_lpi), "cols\n")

# Country distance
df_distance <- read_csv(here(PROCESSED_DATA_PATH, "country_distance.csv"), show_col_types = FALSE)
cat("  Distance:", nrow(df_distance), "rows x", ncol(df_distance), "cols\n\n")

# --------------------------------------------------
# 2. Calculate supply chain concentration indicators
# --------------------------------------------------
cat("Step 2: Calculating supply chain concentration indicators...\n")
cat("  Grouping by (reporter, year, sector, flow)...\n")

# For each reporter-year-sector-flow combination, calculate:
# - HHI (Herfindahl-Hirschman Index): sum of squared shares
# - CR3: combined share of top 3 partners
# - Top1/Top2/Top3 partner names and shares

# First, calculate total value per group for share verification
df_concentration <- df_comtrade %>%
  group_by(reporter_iso3, year, sector_name, flow) %>%
  arrange(desc(value_kusd), .by_group = TRUE) %>%
  mutate(
    rank = row_number(),
    # HHI: sum of squared market shares (share is already a fraction)
    hhi = sum(share^2, na.rm = TRUE),
    # Top partners
    top1_partner = ifelse(rank == 1, partner_iso3, NA_character_),
    top1_share   = ifelse(rank == 1, share, NA_real_),
    top2_partner = ifelse(rank == 2, partner_iso3, NA_character_),
    top2_share   = ifelse(rank == 2, share, NA_real_),
    top3_partner = ifelse(rank == 3, partner_iso3, NA_character_),
    top3_share   = ifelse(rank == 3, share, NA_real_)
  ) %>%
  # CR3: sum of top 3 shares
  mutate(cr3 = sum(top1_share, top2_share, top3_share, na.rm = TRUE)) %>%
  # Fill down within group so every row has the group-level indicators
  fill(top1_partner, top1_share, top2_partner, top2_share,
       top3_partner, top3_share, .direction = "downup") %>%
  ungroup() %>%
  select(-rank)

cat("  Concentration indicators calculated.\n")
cat("  HHI range:", round(min(df_concentration$hhi, na.rm = TRUE), 4),
    "-", round(max(df_concentration$hhi, na.rm = TRUE), 4), "\n")
cat("  CR3 range:", round(min(df_concentration$cr3, na.rm = TRUE), 4),
    "-", round(max(df_concentration$cr3, na.rm = TRUE), 4), "\n\n")

# Free original Comtrade memory
rm(df_comtrade)
gc()

# --------------------------------------------------
# 3. Merge with TiVA GVC indicators (by reporter country & year)
# --------------------------------------------------
cat("Step 3: Merging with TiVA GVC indicators...\n")

# TiVA is at country-year level, join on reporter_iso3 = iso3 and year
df_master <- df_concentration %>%
  left_join(
    df_tiva %>% select(-country_name),
    by = c("reporter_iso3" = "iso3", "year" = "year")
  )

cat("  After TiVA merge:", nrow(df_master), "rows x", ncol(df_master), "cols\n")
tiva_match_rate <- mean(!is.na(df_master$gvc_participation_pct)) * 100
cat("  TiVA match rate:", round(tiva_match_rate, 1), "%\n\n")

rm(df_tiva)
gc()

# --------------------------------------------------
# 4. Merge with LPI logistics performance (by reporter country & year)
# --------------------------------------------------
cat("Step 4: Merging with LPI logistics performance...\n")

df_master <- df_master %>%
  left_join(
    df_lpi %>% select(-country_name),
    by = c("reporter_iso3" = "iso3", "year" = "year")
  )

cat("  After LPI merge:", nrow(df_master), "rows x", ncol(df_master), "cols\n")
lpi_match_rate <- mean(!is.na(df_master$lpi_score)) * 100
cat("  LPI match rate:", round(lpi_match_rate, 1), "%\n\n")

rm(df_lpi)
gc()

# --------------------------------------------------
# 5. Merge with geographic distance (by reporter & partner)
# --------------------------------------------------
cat("Step 5: Merging with geographic distance...\n")

df_master <- df_master %>%
  left_join(
    df_distance,
    by = c("reporter_iso3", "partner_iso3")
  )

cat("  After distance merge:", nrow(df_master), "rows x", ncol(df_master), "cols\n")
dist_match_rate <- mean(!is.na(df_master$distance_km)) * 100
cat("  Distance match rate:", round(dist_match_rate, 1), "%\n\n")

rm(df_distance, df_concentration)
gc()

# --------------------------------------------------
# 6. Add region classification for regionalization analysis
# --------------------------------------------------
cat("Step 6: Adding world region classification...\n")

# Add reporter region
df_master <- df_master %>%
  mutate(
    reporter_region = countrycode(reporter_iso3, origin = "iso3c", destination = "region"),
    partner_region  = countrycode(partner_iso3, origin = "iso3c", destination = "region")
  )

cat("  Regions added. Reporter regions:\n")
print(table(df_master$reporter_region, useNA = "ifany"))
cat("\n")

# --------------------------------------------------
# 7. Final validation & summary
# --------------------------------------------------
cat("========== FINAL MASTER PANEL SUMMARY ==========\n\n")
cat("Dimensions:", nrow(df_master), "rows x", ncol(df_master), "columns\n")
cat("Years:", paste(sort(unique(df_master$year)), collapse = ", "), "\n")
cat("Reporter countries:", n_distinct(df_master$reporter_iso3), "\n")
cat("Partner countries:", n_distinct(df_master$partner_iso3), "\n")
cat("Sectors:", n_distinct(df_master$sector_name), "\n")
cat("Flow types:", paste(unique(df_master$flow), collapse = ", "), "\n\n")

cat("--- Key indicator ranges ---\n")
cat("HHI:              min =", round(min(df_master$hhi, na.rm = TRUE), 4),
    "  max =", round(max(df_master$hhi, na.rm = TRUE), 4),
    "  mean =", round(mean(df_master$hhi, na.rm = TRUE), 4), "\n")
cat("CR3:              min =", round(min(df_master$cr3, na.rm = TRUE), 4),
    "  max =", round(max(df_master$cr3, na.rm = TRUE), 4),
    "  mean =", round(mean(df_master$cr3, na.rm = TRUE), 4), "\n")
cat("LPI score:        min =", round(min(df_master$lpi_score, na.rm = TRUE), 2),
    "  max =", round(max(df_master$lpi_score, na.rm = TRUE), 2),
    "  mean =", round(mean(df_master$lpi_score, na.rm = TRUE), 2), "\n")
cat("GVC participation: min =", round(min(df_master$gvc_participation_pct, na.rm = TRUE), 1),
    "  max =", round(max(df_master$gvc_participation_pct, na.rm = TRUE), 1),
    "  mean =", round(mean(df_master$gvc_participation_pct, na.rm = TRUE), 1), "\n")
cat("Distance (km):    min =", round(min(df_master$distance_km, na.rm = TRUE), 0),
    "  max =", round(max(df_master$distance_km, na.rm = TRUE), 0), "\n\n")

# Missing values overview
cat("--- Missing values (top 10) ---\n")
missing_counts <- sapply(df_master, function(x) sum(is.na(x)))
missing_counts <- sort(missing_counts[missing_counts > 0], decreasing = TRUE)
print(head(missing_counts, 10))
cat("\n")

# --------------------------------------------------
# 8. Export master panel
# --------------------------------------------------
cat("========== EXPORTING MASTER PANEL ==========\n\n")

# Export full master panel as CSV (primary data source for Power BI)
write_csv(df_master, here(PROCESSED_DATA_PATH, "master_trade_gvc_panel.csv"))
fsize <- file.info(here(PROCESSED_DATA_PATH, "master_trade_gvc_panel.csv"))$size
cat("Exported: master_trade_gvc_panel.csv\n")
cat("  Rows:", nrow(df_master), "\n")
cat("  Columns:", ncol(df_master), "\n")
cat("  File size:", round(fsize / 1024 / 1024, 2), "MB\n\n")

# Also export an import-only subset for focused analysis
df_imports <- df_master %>% filter(flow == "import")
write_csv(df_imports, here(PROCESSED_DATA_PATH, "import_flows_only.csv"))
cat("Exported: import_flows_only.csv (", nrow(df_imports), "rows )\n\n")

# Free memory
rm(df_master, df_imports)
gc()

cat("========== MASTER PANEL BUILD COMPLETE ==========\n")
cat("All files saved to:", PROCESSED_DATA_PATH, "\n")
cat("\nNext: Run 03_indicator_analysis.R for trend & correlation analysis.\n")
