# Global Manufacturing Supply Chain Resilience Analysis (2019–2024)
# Analyse de la Résilience des Chaînes d'Approvisionnement Manufacturières Mondiales (2019–2024)

> **EN** — Analysis of global manufacturing supply chain restructuring, friend-shoring / near-shoring trends and regionalization of global value chains (2019–2024).
>
> **FR** — Analyse de la restructuration des chaînes d'approvisionnement manufacturières mondiales, des tendances du « friend-shoring » / « near-shoring » et de la régionalisation des chaînes de valeur (2019–2024).

---

## 📊 Project Overview / Vue d'ensemble

**EN**
This project investigates how global manufacturing trade flows have shifted since 2019, which industries are regionalizing their supply chains, and how logistics infrastructure influences supply chain concentration. It combines reproducible R-based data analysis with an interactive Power BI dashboard.

**FR**
Ce projet étudie l'évolution des flux commerciaux manufacturiers mondiaux depuis 2019, identifie les secteurs dont les chaînes d'approvisionnement se régionalisent, et analyse l'infrastructure logistique comme déterminant de la concentration des chaînes. Il combine une analyse de données reproductible en R et un tableau de bord interactif Power BI.

### Key Questions / Questions clés
1.  **EN** How have global manufacturing trade flows shifted after 2019?
    **FR** Comment les flux commerciaux manufacturiers mondiaux ont-ils évolué depuis 2019 ?
2.  **EN** Which industries have seen increased supply chain regionalization?
    **FR** Quels secteurs ont connu une régionalisation accrue de leurs chaînes d'approvisionnement ?
3.  **EN** How does logistics infrastructure (LPI) affect supply chain concentration?
    **FR** Comment la performance logistique (LPI) influence-t-elle la concentration géographique des chaînes ?

---

## 🛠️ Tech Stack / Stack technique

| Composant | Outil / Package | Rôle |
|-----------|-----------------|------|
| Data processing | R (tidyverse, readxl, dplyr, ggplot2) | Téléchargement, nettoyage, calcul des indicateurs |
| Dashboard | Power BI (Azure Maps, DAX basics) | Carte interactive, KPI, slicers |
| Version control | Git / GitHub | Reproductibilité et collaboration |

---

## 📁 Repository Structure / Structure du dépôt

```
global-manufacturing-supply-chain-resilience-2019-2024/
├── R-scripts/
│   ├── 00_setup_environment.R        # Packages, chemins, helpers
│   ├── 01_data_exploration.R          # Chargement et exploration des feuilles Excel
│   ├── 02_build_master_panel.R        # Reconstruction du panneau master, HHI/CR3
│   └── 03_indicator_analysis.R        # Analyses Q1–Q4 + visualisations
├── Power-BI/
│   └── Supply-Chain-Dashboard.pbix    # Tableau de bord interactif
├── data/
│   ├── raw/                           # Données brutes (non versionnées)
│   └── processed/                     # Données nettoyées pour Power BI
├── output/
│   ├── Q1_trade_shift_2019_vs_latest.csv
│   ├── Q2_regionalization_change_ranking.csv
│   ├── Q3_correlation_matrix.csv
│   ├── Q3_regression_results.csv
│   ├── Q4_africa_*.csv
│   └── fig1-5*.png                    # Graphiques d'analyse
└── README.md
```

---

## 📈 Core KPIs / Indicateurs clés

| KPI | Definition / Définition |
|-----|------------------------|
| **Total Imports** | Sum of manufacturing imports (USD thousand) / Somme des importations manufacturières |
| **HHI** | Herfindahl–Hirschman Index of partner concentration (0–1) / Indice de concentration des partenaires |
| **CR3** | Share of top-3 partner countries / Part des 3 premiers pays fournisseurs |
| **LPI** | World Bank Logistics Performance Index (1–5) / Indice de performance logistique |

---

## 🔍 Key Findings / Principaux résultats

### Q1 — Trade flow shifts / Redistribution des flux
- **EN** Sub-Saharan Africa increased imports from East Asia & Pacific by **+6.62 pp**, while reducing dependence on Europe & Central Asia by **−5.63 pp** between 2019 and the latest available year.
- **FR** L'Afrique subsaharienne a augmenté ses imports en provenance d'Asie de l'Est de **+6,62 points de pourcentage**, tout en réduisant sa dépendance à l'Europe de **−5,63 pp**.

### Q2 — Sectoral regionalization / Régionalisation sectorielle
- **EN** Only **2 out of 11 sectors** became more regionalized: wood pulp & paper (+0.96 pp) and footwear (+0.89 pp). Most manufacturing sectors actually became *more globalized*, not less.
- **FR** Seuls **2 secteurs sur 11** se sont régionalisés : bois/papier (+0,96 pp) et chaussures (+0,89 pp). La plupart des secteurs se sont au contraire *davantage mondialisés*.

### Q3 — LPI and concentration / Logistique et concentration
- **EN** Correlation between LPI and HHI = **−0.474** (p < 0.001): countries with better logistics tend to have *less concentrated* supply sources.
- **FR** Corrélation LPI–HHI = **−0,474** (p < 0,001) : les pays avec une meilleure logistique ont des sources d'approvisionnement *moins concentrées*.

### Q4 — Africa / L'Afrique
- **EN** Intra-African trade declined from **6.03% (2019)** to **4.88% (2023)**. African HHI remains above the global average, indicating higher supply chain vulnerability.
- **FR** Le commerce intra-africain est passé de **6,03 % (2019)** à **4,88 % (2023)**. Le HHI africain reste supérieur à la moyenne mondiale, signe d'une vulnérabilité plus élevée.

---

## 🌍 Implications for African Manufacturing / Implications pour l'Afrique

**EN**
The analysis suggests that African manufacturing supply chains remain concentrated and dependent on extra-regional partners (notably East Asia). Improving logistics infrastructure (port efficiency, customs, inland connectivity) is a key lever to diversify suppliers and reduce HHI. Deepening the AfCFTA intra-African trade agenda could reverse the declining intra-regional share observed since 2019.

**FR**
L'analyse montre que les chaînes d'approvisionnement manufacturières africaines restent concentrées et dépendantes de partenaires extra-régionaux (notamment l'Asie de l'Est). L'amélioration des infrastructures logistiques (ports, douanes, connectivité intérieure) est un levier clé pour diversifier les fournisseurs et réduire le HHI. Approfondir l'agenda de l'AfCFTA pourrait inverser la baisse du commerce intra-régional observée depuis 2019.

---

## 📊 Dashboard Preview

**Full dashboard view / Vue d'ensemble :**

![Dashboard Overview](Power-BI/screenshots/ScreenShot%201.png)

**Interactive world map / Carte du monde interactive :**

![World Map](Power-BI/screenshots/ScreenShot%202.png)

**Sector ranking / Classement des secteurs :**

![Sector Bar Chart](Power-BI/screenshots/ScreenShot%203.png)

**Trade evolution by region / Évolution du commerce par région :**

![Trade Trend](Power-BI/screenshots/ScreenShot%204.png)

The Power BI dashboard includes:
- Interactive world map (bubble size = import volume)
- 4 KPI cards (Total Imports, Avg HHI, Avg CR3, Avg LPI)
- Slicers by year, region, and sector
- Line chart: trade evolution by region
- Bar chart: sector ranking

---

## ⚠️ Limitations / Limites

- **EN** Data covers 2019–2023 (LPI not available for 2024). Country and sector coverage varies by source. Analysis uses official mirrored trade statistics.
- **FR** Données 2019–2023 (LPI non disponible pour 2024). La couverture pays/secteurs varie selon les sources. Analyse basée sur les statistiques commerciales officielles.

---

## 📚 Data Sources / Sources de données

| Source | Description |
|--------|-------------|
| **UN Comtrade** | Bilateral manufacturing trade flows (imports by reporter × partner × product) |
| **OECD TiVA** | Trade in Value Added, GVC participation indicators |
| **World Bank LPI** | Logistics Performance Index (infrastructure, customs, timeliness) |

---

## 📌 License

MIT License — feel free to reuse, adapt and cite.
