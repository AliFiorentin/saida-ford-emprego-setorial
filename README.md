# Ford's Exit and Sectoral Employment in Brazil

**Triple Differences Estimation with Fixed Effects, Event Study, and Robustness Tests**

> **Authors:**
> Shauna Bobadilha Rodrigues de Lima (UFPel) ·
> Alisson Tallys Geraldo Fiorentin (UFRGS) ·
> Gibran da Silva Teixeira (FURG)

> **Note:** The full article (`artigo/main.tex` and `artigo/main.pdf`) is written in **Portuguese**.

---

## Abstract

This paper estimates the causal effect of Ford's industrial shutdown in Brazil, announced in 2021 and concentrated in the manufacturing plants of **Camaçari (BA)**, **Taubaté (SP)**, and **Horizonte (CE)**, on formal employment within the automotive complex. We utilize administrative microdata from the Brazilian *Relação Anual de Informações Sociais* (RAIS) for the 2014–2023 period, aggregated at the municipality × sector × year level to provide a precise micro-territorial analysis. The identification strategy relies on a triple-differences (DDD) design, exploiting simultaneous variation over time (pre/post-2021), across space (treated versus non-treated municipalities), and across sectors (automotive complex versus other economic sectors). The empirical specification includes high-dimensional fixed effects (municipality–year, sector–year, and municipality–sector) and municipality-clustered standard errors to ensure the robustness of the statistical inference. The main estimate is negative and statistically significant ($\hat{\beta} = -1.3992$; $p = 0.0034$), implying an approximate $75.3\%$ reduction in formal sectoral employment in the directly exposed locations after 2021. An event-study specification shows no differential dynamics prior to the treatment and a persistent contraction following the shock. Overall, the evidence suggests that Ford's exit represented a major local economic shock with persistent adverse effects on formal employment in the automotive complex in directly exposed areas.

**Keywords:** Ford's Exit from Brazil · Automotive Sector · Local Economic Shock · Labor Market · Triple Differences-in-Differences

**JEL Codes:** J23 · J65 · C23

---

## Main Results

<div align="center">

| Result | Value |
|:---|:---|
| DDD coefficient ( $\hat{\beta}$ ) | −1.3992 |
| Standard error (municipal cluster) | 0.477 |
| p-value | 0.0034 |
| Percentage effect $\left(e^{\hat{\beta}}-1\right)$ | **−75.3%** |
| Spatial placebo p-value (Fisher, B = 2,000) | ≈ 0.0005 |

</div>

---

## Research Objectives

1. Causally estimate the impact of Ford's plant closures on formal employment in the directly exposed municipalities.
2. Isolate the net effect of the Ford shock from aggregate time trends, national sectoral shocks, and local shocks common to all sectors.
3. Assess temporal persistence through an event study and verify parallel pre-treatment trends.
4. Test spatial spillovers to neighboring municipalities via the SLX-DDD model.
5. Validate identification with temporal and spatial (Fisher permutation) placebo tests.
6. Compare six estimators with distinct identification assumptions to demonstrate robustness.

---

## Methodology

### 1. Data

- **Source:** RAIS — formal employment contracts active on 31 December, states BA, SP, and CE, 2014–2023
- **Unit:** municipality $m$ × sector $s$ × year $t$
- **Treated municipalities:** Camaçari/BA (IBGE 2905701), Taubaté/SP (IBGE 3554102), Horizonte/CE (IBGE 2305233)
- **Treatment year:** $T_0 = 2021$ (Ford); Horizonte: 2022 (Troller)
- Panel completed with $\text{Emp}_{mst} = 0$ for municipality–sector–year cells with no observed contracts

**Employment trend in treated municipalities:**

<div align="center">

| Year | Total contracts | Change |
|:----:|:--------------:|:------:|
| 2019 | 18,182 | — |
| 2020 | 16,528 | −9.1% |
| 2021 | 10,392 | **−37.1%** |
| 2022 |  9,949 | −4.3% |
| 2023 | 10,090 | +1.4% |

</div>

### 2. Automotive Complex — CNAE 2.0

<div align="center">

| Code | Description |
|:------:|:-----------|
| 29.10-7 | Manufacturing of automobiles, vans, and utility vehicles |
| 29.20-4 | Manufacturing of trucks and buses |
| 29.30-1 | Manufacturing of cabins, bodies, and trailers |
| 29.41-7 to 29.49-2 | Manufacturing of auto parts and accessories |
| 29.50-6 | Reconditioning and recovery of vehicle engines |
| 45.11-1 to 45.43-9 | Trade, maintenance, and representation of vehicles |

</div>

### 3. Outcome Variable

$$Y_{mst} = \ln(\text{Emp}_{mst} + 1)$$

The $+1$ adjustment avoids sample loss from zero-employment cells and preserves approximate percentage interpretation. The implied percentage change in the estimated coefficient is:

$$\%\Delta\text{Emp} = 100 \cdot \left(e^{\hat{\beta}} - 1\right)$$

### 4. Binary Indicators

$$D_m = \mathbf{1}\{m \in \{\text{Camaçari, Taubaté, Horizonte}\}\}$$

$$S_s = \mathbf{1}\{s \in \text{automotive complex}\}$$

$$\text{Post}_t = \mathbf{1}\{t \geq T_0\}, \quad T_0 = 2021$$

The central identification term is the triple interaction:

$$\text{DDD}_{mst} = D_m \times S_s \times \text{Post}_t$$

### 5. Main Model — DDD with High-Dimensional Fixed Effects

$$\boxed{Y_{mst} = \beta \cdot \text{DDD}_{mst} + \alpha_{m \times t} + \gamma_{s \times t} + \delta_{m \times s} + \varepsilon_{mst}}$$

<div align="center">

| Fixed effect | Notation | What it absorbs |
|:---:|:---:|:---|
| Municipality–year | $\alpha_{m \times t}$ | Local shocks common to all sectors in a given year |
| Sector–year | $\gamma_{s \times t}$ | Aggregate national sectoral shocks by year |
| Municipality–sector | $\delta_{m \times s}$ | Persistent structural heterogeneity across municipality-sector pairs |

</div>

**Estimation:** OLS with fixed-effect absorption (`fixest::feols`).  
**Inference:** robust standard errors clustered at the municipal level.

> **Result:** $\hat{\beta} = -1.3992$ (SE $= 0.477$; $p = 0.0034$) $\Rightarrow$ **−75.3%** in formal automotive employment in treated municipalities after 2021.

### 6. Event Study

Let $G_{ms} = D_m \times S_s$. The dynamic specification interacts $G_{ms}$ with year dummies, normalizing base year $T_\text{ref} = T_0 - 1 = 2020$:

$$Y_{mst} = \sum_{l \neq T_{\text{ref}}} \mu_l \cdot \mathbf{1}[t = l] \cdot G_{ms} + \alpha_{m \times t} + \gamma_{s \times t} + \delta_{m \times s} + \varepsilon_{mst}, \quad \mu_{2020} = 0$$

Under conditional parallel trends and no anticipation:

$$\hat{\mu}_l \approx 0 \quad \forall\; l < T_0$$

<p align="center">
  <img src="artigo/figuras/EventStudy_420dpi.png" width="75%" alt="Event Study"/>
  <br><em>Figure 1 — Event study: dynamic treatment effects (DDD with fixed effects). Base year: 2020. 95% confidence bands.</em>
</p>

### 7. Spatial Model — SLX-DDD

To test for spillovers to first-order Queen-contiguous neighboring municipalities:

$$Y_{mst} = \beta_1 \cdot \text{DDD}_{mst} + \beta_2 \cdot \text{DDD}^{\text{nbr}}_{mst} + \alpha_{m \times t} + \gamma_{s \times t} + \delta_{m \times s} + \varepsilon_{mst}$$

where $\text{DDD}^{\text{nbr}}_{mst} = \text{Nbr}_m \times S_s \times \text{Post}_t$, with $\text{Nbr}_m = 1$ for municipalities contiguous to treated ones.

<div align="center">

| Coefficient | Estimate | SE | $p$-value | Interpretation |
|:---:|:---:|:---:|:---:|:---|
| $\hat{\beta}_1$ | −1.4021 | 0.477 | 0.003** | Direct effect on treated municipalities |
| $\hat{\beta}_2$ | −0.2272 | 0.184 | 0.218 | Spillover to neighbors (n.s.) |

</div>

Contiguity matrix: 16 neighboring municipalities (4 of Camaçari, 4 of Horizonte, 8 of Taubaté), built from IBGE 2020 municipal boundaries via `spdep`/`geobr`.

### 8. Temporal Placebo

The true $\text{Post}_t$ indicator is replaced by a placebo $\text{Post}_t^{(p)} = \mathbf{1}\{t \geq T_p\}$ with $T_p < T_0$:

$$\text{DDD}_{mst}^{(p)} = D_m \times S_s \times \text{Post}_t^{(p)}, \quad T_p \in \{2016, 2017, 2018, 2019\}$$

The sample is truncated at $T_0 - 1$. Under the causal hypothesis, $\hat{\beta}^{(p)}$ should be statistically indistinguishable from zero:

<div align="center">

| Placebo year | $\hat{\beta}^{(p)}$ | Significant? |
|:---:|:---:|:---:|
| 2016 | −0.0705 | No |
| 2017 | −0.0128 | No |
| 2018 | +0.0207 | No |
| 2019 | −0.0623 | No |

</div>

### 9. Spatial Placebo — Fisher Permutation

For each replicate $b = 1, \ldots, B$ ($B = 2{,}000$), a placebo set $M^{(b)} \subset \mathcal{C}$ is drawn at random from the control pool:

$$X_{mst}^{(b)} = Z_m^{(b)} \times S_s \times \text{Post}_t, \quad Z_m^{(b)} = \mathbf{1}\{m \in M^{(b)}\}$$

Replicate estimator via Frisch–Waugh–Lovell (FWL):

$$\hat{\beta}^{(b)} = \frac{\displaystyle\sum_{mst} \tilde{X}_{mst}^{(b)}\, \tilde{Y}_{mst}}{\displaystyle\sum_{mst} \left(\tilde{X}_{mst}^{(b)}\right)^2}$$

where $\tilde{Y}$ and $\tilde{X}^{(b)}$ are the variables after *demeaning* by $\alpha_{m \times t}$, $\gamma_{s \times t}$, and $\delta_{m \times s}$. One-sided empirical p-value (with finite-sample smoothing correction):

$$p = \frac{1 + \displaystyle\sum_{b=1}^{B} \mathbf{1}\!\left[\hat{\beta}^{(b)} \leq \hat{\beta}_{\text{real}}\right]}{B + 1}$$

> **Result:** $p \approx 0.0005$ — the true coefficient lies in the extreme tail of the placebo distribution.

<p align="center">
  <img src="artigo/figuras/PlaceboEspacial_420dpi.png" width="75%" alt="Spatial Placebo"/>
  <br><em>Figure 2 — Spatial placebo: distribution of β̂ from Fisher permutations (B = 2,000). Red dashed line: true coefficient. p-value ≈ 0.0005.</em>
</p>

### 10. Alternative Estimators (Robustness)

#### Simple DD

Subsample restricted to the automotive sector only. No cross-sector "third difference":

$$Y_{mt} = \tau \cdot (D_m \times \text{Post}_t) + \alpha_{m} + \gamma_{t} + \varepsilon_{mt}$$

#### Sun & Abraham (2021)

Cohort-weighted estimator via `fixest::sunab` to avoid contamination from heterogeneous treatment effects:

$$Y_{mst} = \sum_{g}\sum_{l \neq -1} \delta_{g,l} \cdot \mathbf{1}[\text{cohort}_m = g] \cdot \mathbf{1}[t - g = l] + \alpha_{m \times t} + \varepsilon_{mst}$$

#### Callaway & Sant'Anna (2021)

Doubly robust estimator via `did::att_gt`, with "never treated" control group:

$$\text{ATT}(g, t) = \mathbb{E}\left[Y_t(g) - Y_t(0) \mid G = g\right]$$

aggregated via `aggte(type = "simple")` and `type = "dynamic"`.

#### SDID — Synthetic Difference-in-Differences

Via `synthdid`: combines synthetic unit weighting (like Synthetic Control) with time weighting (like DD), without imposing a parametric fixed-effect structure:

$$\hat{\tau}^{\text{SDID}} = \arg\min_{\tau,\,\alpha,\,\beta} \sum_{m,t} \left(Y_{mt} - \alpha_m - \beta_t - \tau \cdot D_{mt}\right)^2 \hat{\omega}_m \hat{\lambda}_t$$

### 11. Estimator Comparison

<div align="center">

| Model | $\hat{\tau}$ | SE | $p$-value | $\%\Delta\text{Emp}$ |
|:---|:---:|:---:|:---:|:---:|
| **DDD + FE** *(main)* | **−1.3992** | 0.477 | 0.003** | **−75.3%** |
| Spatial DDD (direct) | −1.4021 | 0.477 | 0.003** | −75.4% |
| Simple DD | −1.3689 | 0.472 | 0.004** | −74.6% |
| Sun & Abraham | −1.3286 | 0.476 | 0.005** | −73.6% |
| Callaway & Sant'Anna | −1.3286 | 0.567 | 0.020* | −73.6% |
| SDID | −1.3476 | 0.706 | † | −74.0% |

</div>

† $t = -1.91$; jackknife SE is conservative with $N_{\text{treated}} = 3$. Non-parametric significance confirmed by Fisher placebo ($p \approx 0.0005$). \* $p < 0.05$; \*\* $p < 0.01$.

All six estimators converge within a 1.8 p.p. range (−73.6% to −75.4%), spanning methods with fundamentally distinct identification assumptions.

---

## Research Agenda

1. **Municipal heterogeneity:** decompose the effect separately for Camaçari, Taubaté, and Horizonte, given their distinct plant sizes and the different timing of the Troller closure (2022).
2. **Supply chain effects:** extend the analysis to adjacent sectors (metallurgy, plastics, logistics) to measure the sectoral employment multiplier of the closure.
3. **Adjustment mechanisms:** investigate worker reallocation to other sectors and municipalities using RAIS longitudinal microdata.
4. **Informality and wages:** use PNAD Contínua and fiscal records to capture spillovers to the informal labor market.
5. **Fiscal impact:** estimate the effects on municipal tax revenues (ISS, IPTU) and dependence on intergovernmental transfers.

---

## Repository Structure

```
.
├── artigo/                         ← LaTeX article (in Portuguese)
│   ├── main.tex                    ← Full article source
│   ├── refs.bib                    ← References (37 entries, natbib/apalike)
│   ├── main.pdf                    ← Compiled PDF (20 pages)
│   └── figuras/                    ← Figures used in the article
│       ├── EventStudy_420dpi.png   ← Figure 1: Event study
│       └── PlaceboEspacial_420dpi.png ← Figure 2: Spatial placebo
│
├── scripts/
│   ├── R/
│   │   ├── DDD_FE_Geral.R          ← Main DDD+FE model, event study, placebos
│   │   ├── DDD_Espacial.R          ← SLX-DDD spatial model (Queen contiguity)
│   │   ├── DD_Simples.R            ← Simple DD (robustness)
│   │   ├── EventStudy_SunAbraham.R ← Sun & Abraham estimator (fixest::sunab)
│   │   ├── Callaway_SantAnna.R     ← Callaway & Sant'Anna estimator (did::att_gt)
│   │   ├── SDID.R                  ← Synthetic DID (synthdid)
│   │   └── Estatisticas_Descritivas.R ← Descriptive statistics
│   ├── python/
│   │   ├── Base_RAIS.py            ← Processes raw RAIS microdata → panel
│   │   └── Google_Cloud.py         ← Alternative download via BigQuery (basedosdados)
│   └── stata/
│       └── Exportar_CSV_por_UF.do  ← Adds gvar indicator, exports panels by state
│
├── dados/          ← [not versioned] RAIS CSVs, CNAE, IFDM (~41 MB)
├── outputs/        ← [not versioned] PNG figures generated by R scripts
├── referencias/    ← [not versioned] Reference PDFs (~204 MB)
│
├── config.R        ← [not versioned] Local project path for R
├── config.do       ← [not versioned] Local project path for Stata
├── config.py       ← [not versioned] GCP billing project ID for Python
│
├── .gitignore
└── README.md
```

> **Local configuration:** Copy the appropriate template and set your environment paths before running:
> - R scripts: create `config.R` with `PROJECT_ROOT <- "/your/path/to/project"`
> - Stata script: create `config.do` with `global PROJECT_ROOT "C:\your\path\to\project"`
> - Python (BigQuery): create `config.py` with `BILLING_PROJECT_ID = "your-gcp-project"`

---

## Reproduction Pipeline

```bash
# 1. Process raw RAIS microdata (requires D:\RAIS Vínculos 2014-2023\)
#    Alternative: python scripts/python/Google_Cloud.py  (BigQuery download)
python scripts/python/Base_RAIS.py

# 2. Export state panels with gvar indicator
stata-mp -b do scripts/stata/Exportar_CSV_por_UF.do

# 3. Main estimation (DDD+FE, event study, placebos)
Rscript scripts/R/DDD_FE_Geral.R

# 4. Spatial SLX-DDD model
Rscript scripts/R/DDD_Espacial.R

# 5. Robustness estimators
Rscript scripts/R/DD_Simples.R
Rscript scripts/R/EventStudy_SunAbraham.R
Rscript scripts/R/Callaway_SantAnna.R
Rscript scripts/R/SDID.R
```

## Dependencies

<div align="center">

| Language | Packages |
|:---:|:---|
| R | `fixest`, `dplyr`, `tidyr`, `ggplot2`, `stringr`, `broom`, `writexl`, `sf`, `spdep`, `geobr`, `did`, `synthdid` |
| Python | `pandas`, `scikit-learn`, `numpy`, `basedosdados`, `openpyxl` |
| Stata | MP (`import/export delimited`) |

</div>
