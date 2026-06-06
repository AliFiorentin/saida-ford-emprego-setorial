# ==============================================================================
# Choque Local e Emprego Setorial: Spatial DiD (SLX-DDD)
# Efeito de Spillover sobre Municípios Vizinhos e Outros Setores
# ==============================================================================

# 1) Pacotes -------------------------------------------------------------------
source("config.R"); setwd(PROJECT_ROOT)

# Pacotes tradicionais
library(dplyr)
library(tidyr)
library(fixest)
library(ggplot2)
library(stringr)
library(broom)

# Pacotes Espaciais
library(sf)
library(spdep)
library(geobr)

# 2) Parâmetros ----------------------------------------------------------------
files <- c(
  "dados/RAIS_Painel_BA.csv",
  "dados/RAIS_Painel_CE.csv",
  "dados/RAIS_Painel_SP.csv"
)
data_sep <- ";"

treated_municipios <- c("Camacari", "Horizonte", "Taubate")  # sem acentos para match seguro
treat_sec_name     <- "AUTOMOBILÍSTICO"
treat_year         <- 2021
ref_year           <- treat_year - 1

# Códigos IBGE de 7 dígitos (evita problemas de encoding com nomes acentuados)
IBGE_CAMACARI  <- 2905701
IBGE_HORIZONTE <- 2305233
IBGE_TAUBATE   <- 3554102
treated_codes_6 <- c("290570", "230523", "355410")  # primeiros 6 dígitos (formato do painel)

# 3) Matriz de Pesos Espaciais e Vizinhos --------------------------------------
cat("Baixando as malhas municipais do IBGE via geobr...\n")
shapes_ba <- read_municipality(code_muni = "BA", year = 2020, showProgress = FALSE)
shapes_ce <- read_municipality(code_muni = "CE", year = 2020, showProgress = FALSE)
shapes_sp <- read_municipality(code_muni = "SP", year = 2020, showProgress = FALSE)

shapes_all <- rbind(shapes_ba, shapes_ce, shapes_sp)

cat("Calculando matriz de vizinhança (Contiguidade Queen)...\n")
nb <- poly2nb(shapes_all)

# Buscar municípios tratados por código IBGE (robusto a encoding)
idx_camacari  <- which(shapes_all$code_muni == IBGE_CAMACARI)
idx_horizonte <- which(shapes_all$code_muni == IBGE_HORIZONTE)
idx_taubate   <- which(shapes_all$code_muni == IBGE_TAUBATE)
idx_tratados  <- c(idx_camacari, idx_horizonte, idx_taubate)

stopifnot(
  "Camaçari não encontrado no shapefile" = length(idx_camacari) == 1,
  "Horizonte não encontrado no shapefile" = length(idx_horizonte) == 1,
  "Taubaté não encontrado no shapefile"   = length(idx_taubate)   == 1
)

# Identificando os índices dos vizinhos (1ª Ordem)
neighbors_idx <- unique(c(nb[[idx_camacari]], nb[[idx_horizonte]], nb[[idx_taubate]]))
neighbors_idx <- neighbors_idx[neighbors_idx > 0]

# Códigos de 6 dígitos dos vizinhos (para match com o painel)
neighbor_codes_6 <- substr(as.character(shapes_all$code_muni[neighbors_idx]), 1, 6)
neighbor_codes_6 <- setdiff(neighbor_codes_6, treated_codes_6)

cat("Municípios Vizinhos (Efeito Indireto):",
    paste(shapes_all$name_muni[neighbors_idx], collapse=", "), "\n\n")

# 4) Leitura e Construção do Painel --------------------------------------------
pick_id_mun <- function(df){
  nms <- names(df)
  cand_code <- c("id_municipio", "cod_municipio", "codigo_municipio", "id_municipio_ibge", 
                 "cod_ibge", "ibge", "codigo_ibge", "mun_cod", "mun_ibge", "id_mun")
  code_col <- cand_code[cand_code %in% nms]
  cand_uf <- c("uf", "sigla_uf", "uf_sigla", "estado")
  uf_col <- cand_uf[cand_uf %in% nms]
  
  if(length(code_col) >= 1){
    df <- df %>% mutate(id_mun = as.character(.data[[code_col[1]]]))
    return(df)
  }
  if(length(uf_col) >= 1){
    df <- df %>% mutate(id_mun = paste0(as.character(.data[[uf_col[1]]]), "_", as.character(id_municipio_nome)))
    return(df)
  }
  df %>% mutate(id_mun = as.character(id_municipio_nome))
}

read_one_base <- function(path, sep=";"){
  raw <- read.csv(path, sep = sep, stringsAsFactors = FALSE)
  raw <- raw %>% mutate(
    id_municipio_nome = as.character(id_municipio_nome),
    secao = as.character(secao),
    ano = as.integer(ano),
    empregados = suppressWarnings(as.numeric(empregados))
  )
  raw <- pick_id_mun(raw)
  raw %>% group_by(id_mun, id_municipio_nome, secao, ano) %>%
    summarise(emp = sum(empregados, na.rm = TRUE), .groups = "drop")
}

panel_all <- bind_rows(lapply(files, read_one_base, sep = data_sep))

# Completar painel com zeros
years_all <- seq(min(panel_all$ano, na.rm = TRUE), max(panel_all$ano, na.rm = TRUE))
mun_lookup <- panel_all %>% distinct(id_mun, id_municipio_nome)

panel_msy <- panel_all %>%
  select(id_mun, secao, ano, emp) %>%
  group_by(id_mun, secao, ano) %>%
  summarise(emp = sum(emp, na.rm = TRUE), .groups = "drop") %>%
  tidyr::complete(id_mun, secao, ano = years_all, fill = list(emp = 0)) %>%
  left_join(mun_lookup, by = "id_mun") %>%
  mutate(
    treat_m    = as.integer(id_mun %in% treated_codes_6),
    neighbor_m = as.integer(id_mun %in% neighbor_codes_6),
    post       = as.integer(ano >= treat_year),
    y_log      = log(emp + 1)
  )

# ==============================================================================
# FUNÇÃO PARA ESTIMAR O MODELO PARA QUALQUER SETOR
# ==============================================================================
estimar_efeito_setor <- function(df, nome_setor) {
  df_setor <- df %>%
    mutate(
      treat_s  = as.integer(secao == nome_setor),
      ddd      = treat_m * treat_s * post,
      treat_ms = treat_m * treat_s,
      ddd_espacial = neighbor_m * treat_s * post,
      neighbor_ms = neighbor_m * treat_s
    )
  
  modelo <- feols(y_log ~ ddd + ddd_espacial | id_mun^ano + secao^ano + id_mun^secao, 
                  data = df_setor, cluster = ~ id_mun, lean = TRUE)
  return(modelo)
}

# 5) Estimação Spatial DiD (Setor Automobilístico) -----------------------------
cat("Estimando SLX-DDD para Setor Automobilístico...\n")
m_ddd_auto <- estimar_efeito_setor(panel_msy, "AUTOMOBILÍSTICO")
print(summary(m_ddd_auto))

# 6) Testando Spillover em Outros Setores (Robustez) ---------------------------
cat("\n==============================================================================\n")
cat("TESTANDO EFEITOS EM OUTROS SETORES (HOUVE TRANSBORDAMENTO PARA FORA DO SETOR AUTOMOTIVO?)\n")
cat("==============================================================================\n")

setores_para_testar <- setdiff(unique(panel_msy$secao), treat_sec_name)
setores_para_testar <- sort(setores_para_testar[!is.na(setores_para_testar)])

resultados_outros_setores <- list()

for (setor_real in setores_para_testar) {
  cat(sprintf("\n--- Setor: %s ---\n", setor_real))
  mod <- estimar_efeito_setor(panel_msy, setor_real)
  
  # Extrai p-valor e coeficiente
  tidied <- broom::tidy(mod)
  coef_dir <- tidied %>% filter(term == "ddd")
  coef_esp <- tidied %>% filter(term == "ddd_espacial")

  if (nrow(coef_dir) == 0 || nrow(coef_esp) == 0) {
    cat("  [PULADO] Regressores colineares ou sem variação suficiente.\n")
    next
  }

  cat(sprintf("Efeito Direto (Pólos)   : Coef = %.4f | p-valor = %.4f %s\n",
              coef_dir$estimate, coef_dir$p.value, ifelse(coef_dir$p.value < 0.05, "**", "")))
  cat(sprintf("Spillover (Vizinhos): Coef = %.4f | p-valor = %.4f %s\n",
              coef_esp$estimate, coef_esp$p.value, ifelse(coef_esp$p.value < 0.05, "**", "")))
}
cat("\n==============================================================================\n")

cat("\n[OK] Teste de setores finalizado.\n")


