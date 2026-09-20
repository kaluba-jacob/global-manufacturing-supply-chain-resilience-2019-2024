# ==================================================
# Project: Global Manufacturing Supply Chain Resilience 2019-2024
# Script: 03_indicator_analysis.R
# Description: Core indicator analysis around three business questions:
#   Q1. How has global manufacturing trade flow shifted after 2019?
#   Q2. Which industries have seen increased supply chain regionalization?
#   Q3. How does logistics infrastructure affect supply chain concentration?
#   Plus: Deep-dive on African manufacturing supply chains.
# Output: Analysis result tables (CSV) + visualizations (PNG) in output/
# ==================================================

# Run environment setup first
source(here("R-scripts", "00_setup_environment.R"))

cat("========== STAGE 3: CORE INDICATOR ANALYSIS ==========\n\n")

# --------------------------------------------------
# 0. Load master panel (only needed columns for memory efficiency)
# --------------------------------------------------
cat("Step 0: Loading master panel...\n")

df_master <- read_csv(
  here(PROCESSED_DATA_PATH, "master_trade_gvc_panel.csv"),
  col_types = cols_only(
    reporter_iso3 = col_character(),
    reporter_name = col_character(),
    reporter_region = col_character(),
    partner_iso3 = col_character(),
    partner_name = col_character(),
    partner_region = col_character(),
    year = col_integer(),
    product_code = col_character(),
    sector_name = col_character(),
    flow = col_character(),
    value_kusd = col_double(),
    share = col_double(),
    hhi = col_double(),
    cr3 = col_double(),
    top1_partner = col_character(),
    top1_share = col_double(),
    gvc_participation_pct = col_double(),
    fva_pct = col_double(),
    lpi_score = col_double(),
    customs = col_double(),
    infrastructure = col_double(),
    logistics_quality = col_double(),
    tracking_tracing = col_double(),
    timeliness = col_double(),
    distance_km = col_double()
  ),
  show_col_types = FALSE
)

cat("  Loaded:", nrow(df_master), "rows x", ncol(df_master), "cols\n")
cat("  Years:", paste(sort(unique(df_master$year)), collapse = ", "), "\n\n")

# Focus on imports for supply chain analysis
df_imports <- df_master %>% filter(flow == "import")
cat("  Import flows:", nrow(df_imports), "rows\n\n")
rm(df_master)
gc()

# ==================================================
# MODULE 1: Trade Flow Shift Analysis (Q1)
# ==================================================
cat("========== MODULE 1: TRADE FLOW SHIFT ANALYSIS ==========\n\n")

# 1.1 Regional import share by year (reporter region <- partner region)
cat("1.1 Calculating regional import share matrix...\n")

region_trade <- df_imports %>%
  filter(!is.na(reporter_region), !is.na(partner_region)) %>%
  group_by(year, reporter_region, partner_region) %>%
  summarise(
    total_value_kusd = sum(value_kusd, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(year, reporter_region) %>%
  mutate(
    region_total = sum(total_value_kusd, na.rm = TRUE),
    import_share_pct = total_value_kusd / region_total * 100
  ) %>%
  ungroup()

write_csv(region_trade, here(OUTPUT_PATH, "Q1_regional_import_shares.csv"))
cat("  Exported: Q1_regional_import_shares.csv (", nrow(region_trade), "rows )\n")

# 1.2 Compare 2019 vs 2024 (or latest available year)
latest_year <- max(df_imports$year, na.rm = TRUE)
base_year <- 2019
cat("1.2 Comparing", base_year, "vs", latest_year, "trade shifts...\n")

trade_shift <- region_trade %>%
  filter(year %in% c(base_year, latest_year)) %>%
  select(year, reporter_region, partner_region, import_share_pct) %>%
  pivot_wider(names_from = year, values_from = import_share_pct,
              names_prefix = "share_") %>%
  mutate(
    share_change_pct = .data[[paste0("share_", latest_year)]] - .data[[paste0("share_", base_year)]],
    share_change_abs = abs(share_change_pct)
  ) %>%
  arrange(desc(share_change_abs))

write_csv(trade_shift, here(OUTPUT_PATH, "Q1_trade_shift_2019_vs_latest.csv"))
cat("  Exported: Q1_trade_shift_2019_vs_latest.csv\n")
cat("  Top 5 largest shifts:\n")
print(head(trade_shift, 5))
cat("\n")

# 1.3 Global top import partners trend
cat("1.3 Global top import source countries trend...\n")

global_partners <- df_imports %>%
  group_by(year, partner_iso3, partner_name) %>%
  summarise(total_value = sum(value_kusd, na.rm = TRUE), .groups = "drop") %>%
  group_by(year) %>%
  mutate(global_share_pct = total_value / sum(total_value, na.rm = TRUE) * 100) %>%
  ungroup() %>%
  arrange(year, desc(global_share_pct))

top_partners_2019 <- global_partners %>% filter(year == base_year) %>% head(10)
top_partners_latest <- global_partners %>% filter(year == latest_year) %>% head(10)

write_csv(global_partners, here(OUTPUT_PATH, "Q1_global_partner_trends.csv"))
cat("  Top 5 import sources in", base_year, ":\n")
print(head(top_partners_2019, 5))
cat("  Top 5 import sources in", latest_year, ":\n")
print(head(top_partners_latest, 5))
cat("\n")

rm(region_trade, trade_shift, global_partners, top_partners_2019, top_partners_latest)
gc()

# ==================================================
# MODULE 2: Industry Regionalization Analysis (Q2)
# ==================================================
cat("========== MODULE 2: INDUSTRY REGIONALIZATION ANALYSIS ==========\n\n")

# 2.1 Intra-regional trade share by industry & year
cat("2.1 Calculating intra-regional trade share by industry...\n")

industry_regionalization <- df_imports %>%
  filter(!is.na(reporter_region), !is.na(partner_region)) %>%
  mutate(is_intra_regional = (reporter_region == partner_region)) %>%
  group_by(year, sector_name) %>%
  summarise(
    total_imports = sum(value_kusd, na.rm = TRUE),
    intra_regional_imports = sum(value_kusd[is_intra_regional], na.rm = TRUE),
    intra_regional_share_pct = intra_regional_imports / total_imports * 100,
    avg_hhi = mean(hhi, na.rm = TRUE),
    avg_cr3 = mean(cr3, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(industry_regionalization, here(OUTPUT_PATH, "Q2_industry_regionalization.csv"))
cat("  Exported: Q2_industry_regionalization.csv (", nrow(industry_regionalization), "rows )\n")

# 2.2 Change in regionalization 2019 vs latest
cat("2.2 Ranking industries by regionalization change...\n")

regionalization_change <- industry_regionalization %>%
  filter(year %in% c(base_year, latest_year)) %>%
  select(year, sector_name, intra_regional_share_pct, avg_hhi, avg_cr3) %>%
  pivot_wider(names_from = year,
              values_from = c(intra_regional_share_pct, avg_hhi, avg_cr3),
              names_sep = "_") %>%
  mutate(
    regionalization_change = .data[[paste0("intra_regional_share_pct_", latest_year)]] -
      .data[[paste0("intra_regional_share_pct_", base_year)]],
    hhi_change = .data[[paste0("avg_hhi_", latest_year)]] - .data[[paste0("avg_hhi_", base_year)]],
    cr3_change = .data[[paste0("avg_cr3_", latest_year)]] - .data[[paste0("avg_cr3_", base_year)]]
  ) %>%
  arrange(desc(regionalization_change))

write_csv(regionalization_change, here(OUTPUT_PATH, "Q2_regionalization_change_ranking.csv"))
cat("  Industries with largest regionalization increase:\n")
print(head(regionalization_change %>% select(sector_name, regionalization_change, hhi_change), 5))
cat("\n  Industries with largest regionalization decrease:\n")
print(tail(regionalization_change %>% select(sector_name, regionalization_change, hhi_change), 5))
cat("\n")

# 2.3 Regionalization by region x industry (latest year)
cat("2.3 Regionalization heatmap data (region x industry, latest year)...\n")

region_industry <- df_imports %>%
  filter(year == latest_year, !is.na(reporter_region), !is.na(partner_region)) %>%
  mutate(is_intra_regional = (reporter_region == partner_region)) %>%
  group_by(reporter_region, sector_name) %>%
  summarise(
    total_imports = sum(value_kusd, na.rm = TRUE),
    intra_regional_share_pct = sum(value_kusd[is_intra_regional], na.rm = TRUE) / total_imports * 100,
    avg_hhi = mean(hhi, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(region_industry, here(OUTPUT_PATH, "Q2_region_industry_heatmap.csv"))
cat("  Exported: Q2_region_industry_heatmap.csv (", nrow(region_industry), "rows )\n\n")

rm(industry_regionalization, regionalization_change, region_industry)
gc()

# ==================================================
# MODULE 3: Logistics & Concentration Correlation (Q3)
# ==================================================
cat("========== MODULE 3: LOGISTICS & CONCENTRATION CORRELATION ==========\n\n")

# 3.1 Country-year level aggregation
cat("3.1 Aggregating to country-year level...\n")

country_year <- df_imports %>%
  filter(!is.na(lpi_score)) %>%
  group_by(reporter_iso3, reporter_name, year) %>%
  summarise(
    avg_hhi = mean(hhi, na.rm = TRUE),
    avg_cr3 = mean(cr3, na.rm = TRUE),
    avg_distance = mean(distance_km, na.rm = TRUE),
    total_imports = sum(value_kusd, na.rm = TRUE),
    lpi_score = first(lpi_score),
    customs = first(customs),
    infrastructure = first(infrastructure),
    logistics_quality = first(logistics_quality),
    tracking_tracing = first(tracking_tracing),
    timeliness = first(timeliness),
    gvc_participation = first(gvc_participation_pct),
    .groups = "drop"
  )

write_csv(country_year, here(OUTPUT_PATH, "Q3_country_year_panel.csv"))
cat("  Exported: Q3_country_year_panel.csv (", nrow(country_year), "rows )\n")

# 3.2 Correlation matrix (pooled panel, all available years)
cat("3.2 Correlation matrix (pooled panel, all available years)...\n")
cat("  Note: Using all years because LPI is not available for", latest_year, "\n")

corr_data <- country_year %>%
  select(avg_hhi, avg_cr3, avg_distance, lpi_score, customs, infrastructure,
         logistics_quality, tracking_tracing, timeliness, gvc_participation) %>%
  filter(complete.cases(.))

cat("  Complete observations for correlation:", nrow(corr_data), "\n")

corr_matrix <- cor(corr_data, method = "pearson")
corr_df <- as.data.frame(corr_matrix) %>%
  rownames_to_column("variable")

write_csv(corr_df, here(OUTPUT_PATH, "Q3_correlation_matrix.csv"))
cat("  Correlation matrix (LPI vs concentration):\n")
print(round(corr_matrix[c("avg_hhi", "avg_cr3"),
                         c("lpi_score", "customs", "infrastructure",
                           "logistics_quality", "tracking_tracing", "timeliness")], 3))
cat("\n")

# 3.3 Correlation by industry
cat("3.3 Correlation by industry...\n")

industry_corr <- df_imports %>%
  filter(!is.na(lpi_score)) %>%
  group_by(sector_name, reporter_iso3, year) %>%
  summarise(
    avg_hhi = mean(hhi, na.rm = TRUE),
    lpi_score = first(lpi_score),
    infrastructure = first(infrastructure),
    .groups = "drop"
  ) %>%
  group_by(sector_name) %>%
  summarise(
    corr_hhi_lpi = cor(avg_hhi, lpi_score, use = "complete.obs"),
    corr_hhi_infra = cor(avg_hhi, infrastructure, use = "complete.obs"),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  arrange(corr_hhi_lpi)

write_csv(industry_corr, here(OUTPUT_PATH, "Q3_correlation_by_industry.csv"))
cat("  Industry-level correlation (HHI vs LPI):\n")
print(industry_corr)
cat("\n")

# 3.4 Panel regression: LPI effect on concentration (controlling for year)
cat("3.4 Panel regression: LPI effect on HHI...\n")

reg_data <- country_year %>%
  filter(complete.cases(avg_hhi, lpi_score, year))

model <- lm(avg_hhi ~ lpi_score + factor(year) + log(total_imports), data = reg_data)
cat("  Regression summary:\n")
print(summary(model))
cat("\n")

# Export regression coefficients
reg_coef <- as.data.frame(summary(model)$coefficients) %>%
  rownames_to_column("term")
write_csv(reg_coef, here(OUTPUT_PATH, "Q3_regression_results.csv"))
cat("  Exported: Q3_regression_results.csv\n\n")

rm(country_year, corr_data, corr_matrix, corr_df, industry_corr, reg_data, model, reg_coef)
gc()

# ==================================================
# MODULE 4: African Manufacturing Deep-Dive
# ==================================================
cat("========== MODULE 4: AFRICAN MANUFACTURING DEEP-DIVE ==========\n\n")

# 4.1 Identify African countries
african_iso3 <- countrycode::codelist %>%
  filter(region == "Sub-Saharan Africa" | region == "Middle East & North Africa") %>%
  pull(iso3c) %>%
  na.omit()

cat("4.1 African countries in dataset:", length(african_iso3), "\n")

africa_imports <- df_imports %>%
  filter(reporter_iso3 %in% african_iso3)

cat("  African import flows:", nrow(africa_imports), "rows\n")
cat("  African reporter countries:", n_distinct(africa_imports$reporter_iso3), "\n\n")

# 4.2 Africa import source structure
cat("4.2 Africa import source structure (latest year)...\n")

africa_sources <- africa_imports %>%
  filter(year == latest_year) %>%
  group_by(partner_region, partner_name) %>%
  summarise(total_value = sum(value_kusd, na.rm = TRUE), .groups = "drop") %>%
  mutate(share_pct = total_value / sum(total_value) * 100) %>%
  arrange(desc(total_value))

write_csv(africa_sources, here(OUTPUT_PATH, "Q4_africa_import_sources.csv"))
cat("  Top 10 import sources for Africa:\n")
print(head(africa_sources, 10))
cat("\n")

# 4.3 Africa intra-regional trade trend
cat("4.3 Africa intra-regional trade trend...\n")

africa_intra <- africa_imports %>%
  filter(!is.na(partner_region)) %>%
  mutate(is_african_partner = partner_iso3 %in% african_iso3) %>%
  group_by(year) %>%
  summarise(
    total_imports = sum(value_kusd, na.rm = TRUE),
    intra_africa_imports = sum(value_kusd[is_african_partner], na.rm = TRUE),
    intra_africa_share_pct = intra_africa_imports / total_imports * 100,
    avg_hhi = mean(hhi, na.rm = TRUE),
    avg_cr3 = mean(cr3, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(africa_intra, here(OUTPUT_PATH, "Q4_africa_intra_trade_trend.csv"))
cat("  Africa intra-regional import share trend:\n")
print(africa_intra)
cat("\n")

# 4.4 Africa vs Global comparison
cat("4.4 Africa vs Global comparison...\n")

global_avg <- df_imports %>%
  group_by(year) %>%
  summarise(
    global_avg_hhi = mean(hhi, na.rm = TRUE),
    global_avg_cr3 = mean(cr3, na.rm = TRUE),
    global_avg_lpi = mean(lpi_score, na.rm = TRUE),
    .groups = "drop"
  )

africa_avg <- africa_imports %>%
  group_by(year) %>%
  summarise(
    africa_avg_hhi = mean(hhi, na.rm = TRUE),
    africa_avg_cr3 = mean(cr3, na.rm = TRUE),
    africa_avg_lpi = mean(lpi_score, na.rm = TRUE),
    .groups = "drop"
  )

africa_comparison <- global_avg %>%
  left_join(africa_avg, by = "year") %>%
  mutate(
    hhi_gap = africa_avg_hhi - global_avg_hhi,
    cr3_gap = africa_avg_cr3 - global_avg_cr3,
    lpi_gap = africa_avg_lpi - global_avg_lpi
  )

write_csv(africa_comparison, here(OUTPUT_PATH, "Q4_africa_vs_global_comparison.csv"))
cat("  Africa vs Global (latest year):\n")
print(tail(africa_comparison, 1))
cat("\n")

# 4.5 Top African manufacturing importers & their concentration
cat("4.5 Top African countries by import volume & concentration...\n")

africa_countries <- africa_imports %>%
  filter(year == latest_year) %>%
  group_by(reporter_iso3, reporter_name) %>%
  summarise(
    total_imports = sum(value_kusd, na.rm = TRUE),
    avg_hhi = mean(hhi, na.rm = TRUE),
    avg_cr3 = mean(cr3, na.rm = TRUE),
    lpi_score = first(lpi_score),
    top_partner = names(which.max(table(top1_partner))),
    .groups = "drop"
  ) %>%
  arrange(desc(total_imports))

write_csv(africa_countries, here(OUTPUT_PATH, "Q4_africa_country_profiles.csv"))
cat("  Top 8 African manufacturing importers:\n")
print(head(africa_countries, 8))
cat("\n")

rm(african_iso3, africa_imports, africa_sources, africa_intra,
   global_avg, africa_avg, africa_comparison, africa_countries)
gc()

# ==================================================
# MODULE 5: Visualizations
# ==================================================
cat("========== MODULE 5: GENERATING VISUALIZATIONS ==========\n\n")

# Reload needed analysis data
trade_shift <- read_csv(here(OUTPUT_PATH, "Q1_trade_shift_2019_vs_latest.csv"), show_col_types = FALSE)
industry_reg <- read_csv(here(OUTPUT_PATH, "Q2_industry_regionalization.csv"), show_col_types = FALSE)
corr_matrix <- read_csv(here(OUTPUT_PATH, "Q3_correlation_matrix.csv"), show_col_types = FALSE) %>%
  column_to_rownames("variable") %>% as.matrix()
africa_intra <- read_csv(here(OUTPUT_PATH, "Q4_africa_intra_trade_trend.csv"), show_col_types = FALSE)
africa_comp <- read_csv(here(OUTPUT_PATH, "Q4_africa_vs_global_comparison.csv"), show_col_types = FALSE)

# 5.1 Trade flow shift - top 10 partner regions
cat("5.1 Trade flow shift chart...\n")

top_shifts <- trade_shift %>%
  arrange(desc(share_change_abs)) %>%
  head(10) %>%
  mutate(pair = paste(reporter_region, "<-", partner_region))

p1 <- ggplot(top_shifts, aes(x = reorder(pair, share_change_pct), y = share_change_pct,
                               fill = share_change_pct > 0)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("TRUE" = "#2E86AB", "FALSE" = "#E63946"),
                    labels = c("Increase", "Decrease")) +
  labs(title = "Top 10 Regional Trade Flow Shifts (2019 to Latest)",
       subtitle = "Percentage point change in import share",
       x = "", y = "Share Change (pp)", fill = "Direction") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(here(OUTPUT_PATH, "fig1_trade_flow_shift.png"), p1, width = 10, height = 6, dpi = 150)
cat("  Saved: fig1_trade_flow_shift.png\n")

# 5.2 Industry regionalization trend
cat("5.2 Industry regionalization trend chart...\n")

p2 <- ggplot(industry_reg, aes(x = year, y = intra_regional_share_pct, color = sector_name)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_brewer(palette = "Set2") +
  labs(title = "Intra-Regional Import Share by Industry (2019-Latest)",
       subtitle = "Higher = more regionalized supply chain",
       x = "Year", y = "Intra-Regional Share (%)", color = "Industry") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        legend.position = "right")

ggsave(here(OUTPUT_PATH, "fig2_industry_regionalization_trend.png"), p2, width = 10, height = 6, dpi = 150)
cat("  Saved: fig2_industry_regionalization_trend.png\n")

# 5.3 Correlation heatmap
cat("5.3 Correlation heatmap...\n")

corr_melt <- corr_matrix %>%
  as.data.frame() %>%
  rownames_to_column("var1") %>%
  pivot_longer(-var1, names_to = "var2", values_to = "correlation")

p3 <- ggplot(corr_melt, aes(x = var1, y = var2, fill = correlation)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "#E63946", mid = "white", high = "#2E86AB",
                       midpoint = 0, limits = c(-1, 1)) +
  geom_text(aes(label = round(correlation, 2)), size = 3, color = "black") +
  labs(title = "Correlation Matrix: Logistics Performance vs Supply Chain Concentration",
       subtitle = "Pearson correlation, latest year cross-section",
       x = "", y = "", fill = "Correlation") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 13),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(here(OUTPUT_PATH, "fig3_correlation_heatmap.png"), p3, width = 10, height = 8, dpi = 150)
cat("  Saved: fig3_correlation_heatmap.png\n")

# 5.4 Africa intra-trade trend
cat("5.4 Africa intra-regional trade trend...\n")

p4 <- ggplot(africa_intra, aes(x = year, y = intra_africa_share_pct)) +
  geom_line(color = "#2E86AB", linewidth = 1.5) +
  geom_point(color = "#2E86AB", size = 3) +
  geom_text(aes(label = round(intra_africa_share_pct, 1)), vjust = -1, size = 3.5) +
  labs(title = "Intra-African Manufacturing Import Share (2019-Latest)",
       subtitle = "Share of African imports coming from other African countries",
       x = "Year", y = "Intra-Africa Share (%)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14)) +
  ylim(0, max(africa_intra$intra_africa_share_pct, na.rm = TRUE) * 1.2)

ggsave(here(OUTPUT_PATH, "fig4_africa_intra_trade.png"), p4, width = 8, height = 5, dpi = 150)
cat("  Saved: fig4_africa_intra_trade.png\n")

# 5.5 Africa vs Global concentration comparison
cat("5.5 Africa vs Global concentration comparison...\n")

africa_comp_long <- africa_comp %>%
  select(year, africa_avg_hhi, global_avg_hhi, africa_avg_cr3, global_avg_cr3) %>%
  pivot_longer(-year, names_to = c("group", "metric"), names_sep = "_avg_") %>%
  mutate(group = ifelse(group == "africa", "Africa", "Global"))

p5 <- ggplot(africa_comp_long, aes(x = year, y = value, color = group, linetype = metric)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Africa" = "#E63946", "Global" = "#2E86AB")) +
  labs(title = "Supply Chain Concentration: Africa vs Global Average",
       subtitle = "HHI & CR3 trends (higher = more concentrated)",
       x = "Year", y = "Concentration Index", color = "Region", linetype = "Metric") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))

ggsave(here(OUTPUT_PATH, "fig5_africa_vs_global_concentration.png"), p5, width = 10, height = 6, dpi = 150)
cat("  Saved: fig5_africa_vs_global_concentration.png\n\n")

# Clean up
rm(trade_shift, industry_reg, corr_matrix, corr_melt, africa_intra, africa_comp,
   top_shifts, p1, p2, p3, p4, p5, africa_comp_long)
gc()

# ==================================================
# Final Summary
# ==================================================
cat("========== ANALYSIS COMPLETE ==========\n\n")
cat("All output files saved to:", OUTPUT_PATH, "\n\n")
cat("Generated files:\n")
output_files <- list.files(OUTPUT_PATH)
for (f in output_files) {
  fsize <- file.info(here(OUTPUT_PATH, f))$size
  cat("  -", f, "(", round(fsize / 1024, 1), "KB )\n")
}
cat("\nKey findings summary:\n")
cat("  Q1: Trade flow shifts quantified (see Q1_trade_shift_2019_vs_latest.csv)\n")
cat("  Q2: Industry regionalization ranked (see Q2_regionalization_change_ranking.csv)\n")
cat("  Q3: LPI-concentration correlation & regression (see Q3_correlation_matrix.csv)\n")
cat("  Q4: Africa deep-dive with 5 analysis tables & 2 charts\n")
cat("\nNext: Stage 4 - Power BI interactive dashboard development.\n")
