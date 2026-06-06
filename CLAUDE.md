# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an econometrics research project studying the employment impact of Ford's 2021 plant closures in Brazil using a Triple Difference-in-Differences (DDD) strategy. The treated municipalities are Camaçari (BA, IBGE 2905701), Horizonte (CE, IBGE 2305233, Troller closure in 2022), and Taubaté (SP, IBGE 3554102). Control groups are other municipalities in the same three states (BA, CE, SP).

## Folder Structure

```
Shashinha/
├── artigo/          — LaTeX article (main.tex, refs.bib, main.pdf, figuras/)
├── dados/           — All data files (RAIS panels, PIB, Population, CNAE, IFDM)
├── outputs/         — Generated figures (PNGs at 420 DPI)
├── referencias/     — Reference PDFs
├── scripts/
│   ├── R/           — R estimation scripts
│   ├── python/      — Python data-processing scripts
│   └── stata/       — Stata export script
└── CLAUDE.md
```

## Data Pipeline

The pipeline runs in sequence:

1. **`scripts/python/Base_RAIS.py`** — Reads raw RAIS microdata TXT files from `D:\RAIS Vínculos 2014 - 2023\RAIS <year>\`, filters to CE/BA/SP, maps CNAE classes to economic sectors (special cases: CNAE prefix `29` → automotive manufacturing `C.A.`; prefix `45` → automotive commerce `G.A`), and outputs `dados/RAIS_Final_Sem_FaixaEtaria.csv`.

2. **`scripts/stata/Exportar_CSV_por_UF.do`** (Stata) — Reads `dados/RAIS_Final_Sem_FaixaEtaria.csv`, adds `gvar` treatment indicator, and exports `dados/RAIS_Painel_{BA,CE,SP}.csv`.

3. **R scripts** — Consume the three state panel CSVs from `dados/`.

Alternative data source: **`scripts/python/Google_Cloud.py`** downloads RAIS microdata from BigQuery via the `basedosdados` library (project ID `caged-480722`), saving one Parquet per year to `dados_rais/`.

Auxiliary projections (for control variables):
- **`scripts/python/Projecao_PIB.py`** — Linear regression projection of GDP to 2022–2023 from `dados/PIB.csv`, outputs `dados/PIB Ajustado.xlsx`.
- **`scripts/python/Projecao_Populacao.py`** — Same approach for population to 2023.

## Running Scripts

All scripts are run from the **project root** (`C:/Users/Administrator/Documents/Shashinha`). R scripts set the working directory internally via `setwd()`.

```bash
# Python (from project root)
python scripts/python/Base_RAIS.py
python scripts/python/Projecao_PIB.py
python scripts/python/Projecao_Populacao.py
python scripts/python/Google_Cloud.py

# Stata (from project root)
stata-mp -b do scripts/stata/Exportar_CSV_por_UF.do

# R (from project root — scripts set working directory internally)
Rscript scripts/R/Estatisticas_Descritivas.R
Rscript "scripts/R/DDD_FE_Geral.R"
Rscript scripts/R/DDD_Espacial.R
```

## Key R Scripts

- **`scripts/R/DDD_FE_Geral.R`** — Main estimation. Runs DDD with three-way fixed effects (`id_mun^ano + secao^ano + id_mun^secao`) via `fixest::feols`, clustered by municipality. Also runs an event study, temporal placebo (pre-treatment years), and spatial placebo (Fisher permutation test, `B_perm = 2000`). Outputs `outputs/EventStudy_420dpi.png` and `outputs/PlaceboEspacial_420dpi.png`.

- **`scripts/R/DDD_Espacial.R`** — SLX-DDD model adding a spillover term (`ddd_espacial`) for first-order contiguous neighbors, using Queen contiguity matrix built from `geobr` shapefiles via `spdep`. Tests direct effects and spillover for the automotive sector.

- **`scripts/R/Estatisticas_Descritivas.R`** — Descriptive stats on automotive sector employment, exports `dados/Estatisticas_Descritivas_Setorial_Final.xlsx`.

## Key Panel Variables

The panel CSVs (`dados/RAIS_Painel_*.csv`, sep=`;`) contain:
- `id_municipio_nome`, `secao`, `ano`, `empregados`
- `gvar`: treatment indicator (1 = treated municipality × post-treatment years)

Panel construction in R completes the balanced panel with zeros for missing municipality–sector–year combinations.

## R Package Dependencies

`fixest`, `dplyr`, `tidyr`, `ggplot2`, `stringr`, `broom`, `writexl`, `sf`, `spdep`, `geobr`

## Python Dependencies

`pandas`, `scikit-learn`, `numpy`, `basedosdados` (BigQuery), `openpyxl`

## Important Conventions

- The treatment year is 2021 for Camaçari and Taubaté; 2022 for Horizonte (Troller). The R scripts currently use `treat_year = 2021` and the reference year is `treat_year - 1 = 2020`.
- CNAE sector codes use 6-digit municipality codes (first 6 digits of the 7-digit IBGE code) in the spatial script.
- All figures are exported at 420 DPI to `outputs/`.
- The article's `artigo/figuras/` folder contains copies of the two main figures used in the paper.
- CSV files use `;` as delimiter and `utf-8-sig` encoding (Python output) or `utf-8` (Stata output).
