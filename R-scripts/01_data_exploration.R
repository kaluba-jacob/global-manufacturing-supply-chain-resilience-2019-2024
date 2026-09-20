# ==================================================
# Project: Global Manufacturing Supply Chain Resilience 2019-2024
# Script: 01_data_exploration.R
# Description: Load raw Excel data sheet by sheet (memory-efficient),
#              inspect structure, validate coverage, and export cleaned
#              processed datasets for Power BI.
# ==================================================

# Run environment setup first
source(here("R-scripts", "00_setup_environment.R"))

excel_file <- here(RAW_DATA_PATH, "Trade_GVC_full.xlsx")

# --------------------------------------------------
# 1. List sheet names
# --------------------------------------------------
cat("Loading raw data from Excel (memory-efficient mode)...\n\n")
sheet_names <- excel_sheets(excel_file)
cat("Sheets found in file:\n")
print(sheet_names)
cat("\n")

# --------------------------------------------------
# 2. Read & inspect small sheets first
# --------------------------------------------------

# --- Variable definition table ---
cat("========== VARIABLE DEFINITION TABLE ==========\n\n")
df_vardef <- read_excel(excel_file, sheet = "变量定义表")
cat("Dimensions:", dim(df_vardef)[1], "rows x", dim(df_vardef)[2], "columns\n")
print(df_vardef)
cat("\n")

# --- README ---
cat("========== README (first 20 lines) ==========\n\n")
df_readme <- read_excel(excel_file, sheet = "README")
print(head(df_readme, 20))
cat("\n")
rm(df_readme)
gc()

# --------------------------------------------------
# 3. Read & inspect Comtrade bilateral trade
# --------------------------------------------------
cat("========== Comtrade - Bilateral Trade ==========\n\n")
df_comtrade <- read_excel(excel_file, sheet = "Comtrade_双边贸易")
cat("Dimensions:", dim(df_comtrade)[1], "rows x", dim(df_comtrade)[2], "columns\n")
cat("Years:", paste(sort(unique(df_comtrade$year)), collapse = ", "), "\n")
cat("Reporter countries:", n_distinct(df_comtrade$reporter_iso3), "\n")
cat("Partner countries:", n_distinct(df_comtrade$partner_iso3), "\n")
cat("Sectors:", n_distinct(df_comtrade$sector_name), "\n")
cat("Flow types:\n")
print(table(df_comtrade$flow))
cat("\nSectors:\n")
print(sort(unique(df_comtrade$sector_name)))
cat("\nSample (first 3 rows):\n")
print(head(df_comtrade, 3))
cat("\n")

# Export Comtrade clean data
write_csv(df_comtrade, here(PROCESSED_DATA_PATH, "comtrade_bilateral_trade.csv"))
cat("Exported: comtrade_bilateral_trade.csv (", nrow(df_comtrade), "rows )\n\n")

# --------------------------------------------------
# 4. Read & inspect TiVA GVC
# --------------------------------------------------
cat("========== OECD TiVA - GVC Value Added ==========\n\n")
df_tiva <- read_excel(excel_file, sheet = "TiVA_GVC增加值")
cat("Dimensions:", dim(df_tiva)[1], "rows x", dim(df_tiva)[2], "columns\n")
cat("Years:", paste(sort(unique(df_tiva$year)), collapse = ", "), "\n")
cat("Countries:", n_distinct(df_tiva$iso3), "\n")
cat("Missing values:\n")
print(sapply(df_tiva, function(x) sum(is.na(x))))
cat("\nSample (first 5 rows):\n")
print(head(df_tiva, 5))
cat("\n")

write_csv(df_tiva, here(PROCESSED_DATA_PATH, "tiva_gvc_indicators.csv"))
cat("Exported: tiva_gvc_indicators.csv (", nrow(df_tiva), "rows )\n\n")
rm(df_tiva)
gc()

# --------------------------------------------------
# 5. Read & inspect LPI
# --------------------------------------------------
cat("========== World Bank LPI - Logistics Performance ==========\n\n")
df_lpi <- read_excel(excel_file, sheet = "LPI_物流绩效")
cat("Dimensions:", dim(df_lpi)[1], "rows x", dim(df_lpi)[2], "columns\n")
cat("Years:", paste(sort(unique(df_lpi$year)), collapse = ", "), "\n")
cat("Countries:", n_distinct(df_lpi$iso3), "\n")
cat("LPI score range:", min(df_lpi$lpi_score, na.rm = TRUE), "-", max(df_lpi$lpi_score, na.rm = TRUE), "\n")
cat("\nSample (first 5 rows):\n")
print(head(df_lpi, 5))
cat("\n")

write_csv(df_lpi, here(PROCESSED_DATA_PATH, "lpi_logistics_performance.csv"))
cat("Exported: lpi_logistics_performance.csv (", nrow(df_lpi), "rows )\n\n")
rm(df_lpi)
gc()

# --------------------------------------------------
# 6. Read & inspect geographic distance
# --------------------------------------------------
cat("========== CEPII - Geographic Distance ==========\n\n")
df_distance <- read_excel(excel_file, sheet = "地理距离")
cat("Dimensions:", dim(df_distance)[1], "rows x", dim(df_distance)[2], "columns\n")
cat("Country pairs:", nrow(df_distance), "\n")
cat("Distance range (km):", min(df_distance$distance_km, na.rm = TRUE), "-", max(df_distance$distance_km, na.rm = TRUE), "\n")
cat("\nSample (first 5 rows):\n")
print(head(df_distance, 5))
cat("\n")

write_csv(df_distance, here(PROCESSED_DATA_PATH, "country_distance.csv"))
cat("Exported: country_distance.csv (", nrow(df_distance), "rows )\n\n")
rm(df_distance)
gc()

# --------------------------------------------------
# 7. Master panel note (built separately in script 02)
# --------------------------------------------------
cat("========== Master Panel ==========\n\n")
cat("NOTE: The '合并主表' sheet is too large to read directly into memory.\n")
cat("Instead, the master panel will be reconstructed from the exported\n")
cat("component tables in script 02_build_master_panel.R.\n")
cat("This approach is memory-efficient and fully reproducible.\n\n")

# --------------------------------------------------
# 8. Build & export dimension tables for Power BI star schema
# --------------------------------------------------
cat("========== EXPORTING DIMENSION TABLES ==========\n\n")

# Country dimension (from Comtrade)
dim_country <- df_comtrade %>%
  select(reporter_iso3, reporter_name) %>%
  distinct() %>%
  rename(iso3 = reporter_iso3, country_name = reporter_name) %>%
  arrange(iso3)
write_csv(dim_country, here(PROCESSED_DATA_PATH, "dim_country.csv"))
cat("Exported: dim_country.csv (", nrow(dim_country), "countries )\n")

# Sector dimension (from Comtrade)
dim_sector <- df_comtrade %>%
  select(product_code, hs_range, sector_name) %>%
  distinct() %>%
  arrange(product_code)
write_csv(dim_sector, here(PROCESSED_DATA_PATH, "dim_sector.csv"))
cat("Exported: dim_sector.csv (", nrow(dim_sector), "sectors )\n")

# Year dimension (from Comtrade)
dim_year <- df_comtrade %>%
  select(year) %>%
  distinct() %>%
  arrange(year)
write_csv(dim_year, here(PROCESSED_DATA_PATH, "dim_year.csv"))
cat("Exported: dim_year.csv (", nrow(dim_year), "years )\n")

# Variable definitions
write_csv(df_vardef, here(PROCESSED_DATA_PATH, "variable_definitions.csv"))
cat("Exported: variable_definitions.csv\n\n")

# Free memory
rm(df_comtrade, df_vardef, dim_country, dim_sector, dim_year)
gc()

cat("========== EXPLORATION COMPLETE ==========\n")
cat("All component datasets saved to:", PROCESSED_DATA_PATH, "\n")
cat("Files exported so far:\n")
exported_files <- list.files(PROCESSED_DATA_PATH, pattern = "*.csv")
for (f in exported_files) {
  fsize <- file.info(here(PROCESSED_DATA_PATH, f))$size
  cat("  -", f, "(", round(fsize / 1024, 1), "KB )\n")
}
cat("\nNext: Run 02_build_master_panel.R to construct the full master panel.\n")
