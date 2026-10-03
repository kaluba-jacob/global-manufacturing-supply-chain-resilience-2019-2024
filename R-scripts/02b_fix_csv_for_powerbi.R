# ==================================================
# Quick fix: Re-export master panel sorted so Power BI
# can correctly detect column types from first 1000 rows.
# ==================================================
library(tidyverse)
library(here)

cat("Reading master panel CSV...\n")
df <- read_csv(here("data", "processed", "master_trade_gvc_panel.csv"),
               show_col_types = FALSE)
cat("  Loaded:", nrow(df), "rows x", ncol(df), "cols\n")

# Ensure all numeric columns are properly typed
numeric_cols <- c("year", "value_kusd", "share", "hhi", "top1_share",
                  "top2_share", "top3_share", "cr3", "dvx_pct", "fva_pct",
                  "gvc_participation_pct", "forward_participation_pct",
                  "backward_participation_pct", "lpi_score", "lpi_rank",
                  "customs", "infrastructure", "logistics_quality",
                  "tracking_tracing", "timeliness", "distance_km")

for (col in numeric_cols) {
  if (col %in% colnames(df)) {
    df[[col]] <- as.numeric(df[[col]])
  }
}

# Sort: countries WITH TiVA data first, then by country, year, sector
cat("Reordering rows for Power BI type detection...\n")
df <- df %>%
  mutate(has_tiva = !is.na(gvc_participation_pct)) %>%
  arrange(desc(has_tiva), reporter_iso3, year, sector_name, partner_iso3) %>%
  select(-has_tiva)

cat("  First 5 rows now from:", head(df$reporter_name, 5) %>% unique(), "\n")
cat("  TiVA non-null in first 1000 rows:",
    sum(!is.na(head(df$gvc_participation_pct, 1000))), "/ 1000\n")

# Re-export sorted CSV
cat("Writing fixed CSV...\n")
output_path <- here("data", "processed", "master_trade_gvc_panel.csv")
write_csv(df, output_path)

fsize <- file.info(output_path)$size / 1024 / 1024
cat("  Saved:", output_path, "\n")
cat("  File size:", round(fsize, 1), "MB\n")
cat("\nDone! Now re-import this CSV in Power BI - type detection will work correctly.\n")
