# ==============================================================================
# SCRIPT: ESTATÍSTICAS DESCRITIVAS - MÍNIMA E EXPORTAÇÃO XLSX
# PROJETO: Impacto Setorial (BA, CE, SP)
# AUTOR: Alisson Fiorentin
# ==============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(writexl)

# 1. Parâmetros e Configurações de Diretório
source("config.R"); setwd(PROJECT_ROOT)

files <- c("dados/RAIS_Painel_BA.csv", "dados/RAIS_Painel_CE.csv", "dados/RAIS_Painel_SP.csv")
data_sep <- ";"
treat_sec_name <- "AUTOMOBILÍSTICO"
treated_municipios <- c("Camaçari", "Horizonte", "Taubaté")

# 2. Função de Leitura e Padronização de Tipos
# A seleção seletiva de colunas previne erros de classe entre bases distintas
read_rais_clean <- function(path, sep = ";") {
  uf <- str_extract(path, "(?<=_)[A-Z]{2}(?=\\.csv)")
  
  read.csv(path, sep = sep, stringsAsFactors = FALSE) %>%
    select(id_municipio_nome, secao, ano, empregados) %>%
    mutate(
      id_municipio_nome = as.character(id_municipio_nome),
      secao             = as.character(secao),
      ano               = as.integer(ano),
      empregados        = as.numeric(empregados),
      sigla_uf          = uf
    )
}

# 3. Consolidação e Processamento do Painel Setorial
df_total <- bind_rows(lapply(files, read_rais_clean, sep = data_sep))

# Filtragem para o setor automobilístico em todos os municípios
panel_auto <- df_total %>%
  filter(secao == treat_sec_name) %>%
  group_by(sigla_uf, id_municipio_nome, ano) %>%
  summarise(emp = sum(empregados, na.rm = TRUE), .groups = "drop")

# ==============================================================================
# 4. Geração das Estatísticas (Métrica de Mínimo)
# ==============================================================================

# Estatísticas para a amostra completa (Controle e Tratados)
stats_total_completa <- panel_auto %>%
  group_by(ano) %>%
  summarise(
    N_Municipios  = n_distinct(id_municipio_nome),
    Total_Emprego = sum(emp, na.rm = TRUE),
    Media         = mean(emp, na.rm = TRUE),
    SD            = sd(emp, na.rm = TRUE),
    Minimo        = min(emp, na.rm = TRUE),
    Maximo        = max(emp, na.rm = TRUE),
    .groups       = "drop"
  )

# Estatísticas restritas aos municípios tratados
stats_tratados_only <- panel_auto %>%
  filter(id_municipio_nome %in% treated_municipios) %>%
  group_by(ano) %>%
  summarise(
    N_Municipios  = n_distinct(id_municipio_nome),
    Total_Emprego = sum(emp, na.rm = TRUE),
    Media         = mean(emp, na.rm = TRUE),
    SD            = sd(emp, na.rm = TRUE),
    Minimo        = min(emp, na.rm = TRUE),
    Maximo        = max(emp, na.rm = TRUE),
    .groups       = "drop"
  )

# ==============================================================================
# 5. Exportação dos Resultados
# ==============================================================================

lista_exportacao <- list(
  "Amostra_Total"    = stats_total_completa,
  "Apenas_Tratados"  = stats_tratados_only
)

# Exportação direta para Excel
write_xlsx(lista_exportacao, path = "Estatisticas_Descritivas_Setorial_Final.xlsx")

cat("\nO arquivo 'Estatisticas_Descritivas_Setorial_Final.xlsx' foi gerado com as métricas de mínimo.\n")

