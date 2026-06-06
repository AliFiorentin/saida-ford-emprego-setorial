# Saída da Ford e Emprego Setorial no Brasil

**Estimativa DDD com Efeitos Fixos, Estudo de Evento e Testes de Robustez**

**Autores:**
- Shauna Bobadilha Rodrigues de Lima — Doutora em Economia, PPGOM/UFPel
- Alisson Tallys Geraldo Fiorentin — Doutorando em Economia Aplicada, PPGE/UFRGS
- Gibran da Silva Teixeira — Professor Doutor, PPGEA/FURG

---

## Descrição do Artigo

Este artigo estima o efeito causal do encerramento das operações industriais da Ford no Brasil, anunciado em 2021 e concentrado nas plantas de **Camaçari (BA)**, **Taubaté (SP)** e **Horizonte (CE)**, sobre o emprego formal no complexo automotivo.

Utilizamos microdados administrativos da **Relação Anual de Informações Sociais (RAIS)** para o período 2014–2023, agregados ao nível município × setor × ano. A estratégia empírica fundamenta-se no método de **Diferenças em Diferenças Tripla (DDD)**, explorando variações simultâneas no tempo (pré/pós-2021), no espaço (municípios tratados versus não tratados) e no setor (complexo automotivo versus demais setores).

### Resultado Principal

> **β̂ = −1,3992** (EP = 0,477; p = 0,0034)
>
> Redução de aproximadamente **−75,3%** no emprego setorial formal nas localidades diretamente expostas após 2021.

O estudo de evento indica ausência de dinâmicas diferenciais no pré-tratamento e uma contração persistente no período pós-choque (2021–2023). Os placebos temporal e espacial (Fisher, B = 2.000, p ≈ 0,0005) reforçam a interpretação causal.

### Classificação JEL

J23 · J65 · C23

### Palavras-chave

Saída da Ford do Brasil · Setor automotivo · Choque econômico local · Mercado de trabalho · Diferenças em Diferenças Tripla

---

## Objetivos

1. **Estimar causalmente** o impacto do fechamento das plantas da Ford/Troller sobre o emprego formal do complexo automotivo nos municípios diretamente expostos (Camaçari, Taubaté e Horizonte).
2. **Isolar o efeito líquido** do choque da Ford, separando tendências agregadas, choques setoriais nacionais e choques locais comuns a todos os setores.
3. **Avaliar a persistência temporal** do impacto via estudo de evento, verificando a hipótese de tendências paralelas no pré-tratamento.
4. **Testar transbordamento espacial** (spillover) sobre municípios vizinhos por contiguidade Queen, via modelo SLX-DDD.
5. **Validar a identificação** com placebos temporal (anos fictícios pré-2021) e espacial (permutação de Fisher com B = 2.000 réplicas).
6. **Comparar estimadores** (DDD+EF, DD Simples, Sun & Abraham, Callaway & Sant'Anna, SDID) para demonstrar robustez do resultado principal.

---

## Metodologia Completa

### 1. Estratégia de Identificação — DDD

A estratégia explora variação tripla em painéis no nível município × setor × ano, combinando:

- **Dimensão temporal:** pré/pós-choque (2021)
- **Dimensão espacial:** municípios tratados (Camaçari, Taubaté, Horizonte) vs. controles (demais municípios de BA, CE, SP)
- **Dimensão setorial:** complexo automotivo (CNAE prefixo 29 e 45) vs. demais setores

O estimador DDD elimina por sucessivas diferenças componentes não observáveis comuns ao longo do tempo, específicos de localidades e de setores, preservando apenas a variação residual simultaneamente pós-choque, no município tratado e no setor tratado.

### 2. Dados

- **Fonte:** RAIS (Relação Anual de Informações Sociais), vínculos ativos em 31/12, 2014–2023
- **Estados:** Bahia (BA), São Paulo (SP) e Ceará (CE)
- **Unidade analítica:** município × setor (CNAE 2.0) × ano
- **Municípios tratados:** Camaçari/BA (IBGE 2905701), Taubaté/SP (IBGE 3554102), Horizonte/CE (IBGE 2305233)
- **Ano de tratamento:** 2021 para Camaçari e Taubaté (Ford); 2022 para Horizonte (Troller)
- **Painel:** completado com zeros para combinações município-setor-ano sem vínculos observados

**Evolução do emprego nos municípios tratados:**

| Ano  | Total Vínculos |
|------|---------------|
| 2019 | 18.182        |
| 2020 | 16.528        |
| 2021 | 10.392 (−37%) |
| 2022 |  9.949        |
| 2023 | 10.090        |

### 3. Definição do Complexo Automotivo (CNAE 2.0)

| CNAE    | Denominação |
|---------|-------------|
| 29.10-7 | Fabricação de automóveis, camionetas e utilitários |
| 29.20-4 | Fabricação de caminhões e ônibus |
| 29.30-1 | Fabricação de cabines, carrocerias e reboques |
| 29.41-7 | Fabricação de peças para o sistema motor |
| 29.42-5 | Fabricação de peças para sistemas de marcha e transmissão |
| 29.43-3 | Fabricação de peças para o sistema de freios |
| 29.44-1 | Fabricação de peças para o sistema de direção e suspensão |
| 29.45-0 | Fabricação de material elétrico e eletrônico para veículos |
| 29.49-2 | Fabricação de peças para veículos automotores n.e.a. |
| 29.50-6 | Recondicionamento e recuperação de motores |
| 45.11-1 | Comércio a varejo e por atacado de veículos automotores |
| 45.12-9 | Representantes comerciais de veículos automotores |
| 45.20-0 | Manutenção e reparação de veículos automotores |
| 45.30-7 | Comércio de peças e acessórios para veículos |
| 45.41-2 | Comércio por atacado e a varejo de motocicletas |
| 45.42-1 | Representantes comerciais de motocicletas |
| 45.43-9 | Manutenção e reparação de motocicletas |

### 4. Variável Dependente e Indicadores

Variável dependente (log com ajuste aditivo unitário):

```
Y_mst = ln(Emp_mst + 1)
```

Indicadores binários:
- **D_m = 1** se município m pertence ao conjunto tratado
- **S_s = 1** se setor s pertence ao complexo automotivo
- **Post_t = 1** se t ≥ 2021

Termo central da identificação DDD:

```
DDD_mst = D_m × S_s × Post_t
```

### 5. Especificação Principal (DDD com Efeitos Fixos de Alta Dimensão)

```
Y_mst = β · DDD_mst + α_{m×t} + γ_{s×t} + δ_{m×s} + ε_mst
```

Onde:
- **α_{m×t}** — efeitos fixos município-ano: absorvem choques não observados que atingem um município de forma comum a todos os setores em dado ano
- **γ_{s×t}** — efeitos fixos setor-ano: capturam choques setoriais agregados por ano (ciclos nacionais, variações de preços relativos)
- **δ_{m×s}** — efeitos fixos município-setor: controlam heterogeneidade estrutural persistente entre pares município-setor (especialização produtiva histórica)
- **ε_mst** — erro idiossincrático

Estimação: MQO com absorção de efeitos fixos via `fixest::feols`. Inferência: erros-padrão robustos agrupados no nível municipal.

Interpretação do coeficiente em variação percentual:

```
%ΔEmp = 100 × (e^β̂ − 1)
```

### 6. Estudo de Evento (Dinâmica Temporal)

Especificação dinâmica com dummies anuais, ano-base 2020 (T_ref = T₀ − 1):

```
Y_mst = Σ_{l ≠ T_ref} μ_l · 1[t = l] · G_ms + α_{m×t} + γ_{s×t} + δ_{m×s} + ε_mst
```

Onde G_ms = D_m × S_s. Sob tendências paralelas condicionais, espera-se μ_l ≈ 0 para l < 2021.

### 7. Modelo Espacial: SLX-DDD

Para avaliar transbordamento (spillover) para municípios vizinhos por contiguidade Queen:

```
Y_mst = β₁ · DDD_mst + β₂ · DDD^viz_mst + α_{m×t} + γ_{s×t} + δ_{m×s} + ε_mst
```

Onde `DDD^viz_mst = Viz_m × S_s × Post_t`, com Viz_m = 1 para municípios contíguos aos tratados.

- **β₁** — efeito direto sobre as localidades expostas ao choque
- **β₂** — spillover para o entorno imediato no mesmo setor

Matriz de vizinhança Queen de primeira ordem: 16 municípios vizinhos (4 de Camaçari, 4 de Horizonte, 8 de Taubaté), construída a partir das malhas municipais do IBGE 2020 via `spdep`/`geobr`.

### 8. Testes de Robustez

#### Placebo Temporal

Substitui-se o indicador Post_t real por um placebo `Post_t^(p) = 1{t ≥ T_p}` com T_p < 2021, truncando a amostra até T₀ − 1. Resultados para anos placebo 2016–2019:

| Ano placebo | β̂^(p)  | Significativo? |
|-------------|---------|----------------|
| 2016        | −0,0705 | Não            |
| 2017        | −0,0128 | Não            |
| 2018        | +0,0207 | Não            |
| 2019        | −0,0623 | Não            |

#### Placebo Espacial (Permutação de Fisher)

Reatribui-se repetidas vezes o conjunto de municípios tratados (B = 2.000 réplicas) dentro de um pool de municípios comparáveis, construindo distribuição empírica do estimador sob H₀. O p-valor empírico é:

```
p = (#{ β̂^(b) ≤ β̂_real } + 1) / (B + 1)
```

**Resultado:** p ≈ 0,0005 — o coeficiente real está na cauda extrema da distribuição placebo.

### 9. Comparação de Estimadores (Robustez)

| Modelo                  | β̂       | EP    | p-valor   | %ΔEmp   |
|-------------------------|----------|-------|-----------|---------|
| **DDD + EF** (principal)| −1,3992  | 0,477 | 0,003 **  | −75,3%  |
| DDD Espacial (direto)   | −1,4021  | 0,477 | 0,003 **  | −75,4%  |
| DD Simples              | −1,3689  | 0,472 | 0,004 **  | −74,6%  |
| Sun & Abraham (2021)    | −1,3286  | 0,476 | 0,005 **  | −73,6%  |
| Callaway & Sant'Anna    | −1,3286  | 0,567 | 0,020 *   | −73,6%  |
| SDID                    | −1,3476  | 0,706 | —         | −74,0%  |

Todos os estimadores convergem para um efeito negativo de aproximadamente 73–75%, robustecendo a conclusão principal.

---

## Ideias e Agenda de Pesquisa

1. **Heterogeneidade por município:** Desagregar o efeito para Camaçari, Taubaté e Horizonte individualmente, dada a diferença de porte das plantas e do timing do choque da Troller (2022).

2. **Efeitos sobre a cadeia de fornecedores:** Ampliar a análise para setores adjacentes (metalurgia, plásticos, borracha, logística) para mensurar o multiplicador setorial do fechamento.

3. **Comparação com experiências internacionais:** Triangular os resultados com estudos de fechamento de plantas (MG Rover — Birmingham; FIAT — Sul da Itália) para contextualizar a magnitude relativa do choque.

4. **Mecanismos de ajuste:** Investigar se houve realocação de trabalhadores para outros setores nos municípios tratados, usando dados longitudinais de trabalhadores da RAIS.

5. **Impacto fiscal:** Estimar os efeitos do choque sobre arrecadação municipal (ISS, IPTU) e dependência de transferências, complementando a dimensão do bem-estar local.

---

## Estrutura do Repositório

```
.
├── artigo/
│   ├── main.tex          — Artigo completo em LaTeX
│   ├── refs.bib          — Referências bibliográficas (37 entradas)
│   ├── main.pdf          — PDF compilado
│   └── figuras/
│       ├── EventStudy_420dpi.png
│       └── PlaceboEspacial_420dpi.png
├── scripts/
│   ├── R/
│   │   ├── DDD_FE_Geral.R          — Modelo principal DDD + EF
│   │   ├── DDD_Espacial.R          — Modelo SLX-DDD com contiguidade Queen
│   │   ├── DD_Simples.R            — DD convencional (robustez)
│   │   ├── Callaway_SantAnna.R     — Estimador Callaway & Sant'Anna (robustez)
│   │   ├── EventStudy_SunAbraham.R — Estimador Sun & Abraham (robustez)
│   │   ├── SDID.R                  — Diferenças-em-Diferenças Sintéticas (robustez)
│   │   └── Estatisticas_Descritivas.R
│   ├── python/
│   │   ├── Base_RAIS.py            — Processa microdados RAIS brutos
│   │   ├── Google_Cloud.py         — Download via BigQuery (basedosdados)
│   │   ├── Projecao_PIB.py         — Projeção linear do PIB 2022-2023
│   │   └── Projecao_Populacao.py   — Projeção linear de população 2023
│   └── stata/
│       └── Exportar_CSV_por_UF.do  — Exporta painéis por UF com indicador gvar
├── dados/                          — [não versionado — .gitignore]
├── outputs/                        — [não versionado — .gitignore]
├── referencias/                    — [não versionado — .gitignore]
├── CLAUDE.md
└── README.md
```

## Dependências

**R:** `fixest`, `dplyr`, `tidyr`, `ggplot2`, `stringr`, `broom`, `writexl`, `sf`, `spdep`, `geobr`, `did`, `synthdid`

**Python:** `pandas`, `scikit-learn`, `numpy`, `basedosdados`, `openpyxl`

**Stata:** versão MP (para `import delimited` e `export delimited`)

---

## Reprodução

```bash
# 1. Processar microdados RAIS (requer D:\RAIS Vínculos 2014-2023\)
python scripts/python/Base_RAIS.py

# 2. Exportar painéis por UF
stata-mp -b do scripts/stata/Exportar_CSV_por_UF.do

# 3. Estimação principal
Rscript scripts/R/DDD_FE_Geral.R

# 4. Modelo espacial
Rscript scripts/R/DDD_Espacial.R

# 5. Modelos de robustez
Rscript scripts/R/DD_Simples.R
Rscript scripts/R/EventStudy_SunAbraham.R
Rscript scripts/R/Callaway_SantAnna.R
Rscript scripts/R/SDID.R
```

Todos os scripts R utilizam `setwd("C:/Users/Administrator/Documents/Shashinha")` internamente e podem ser executados de qualquer diretório.
