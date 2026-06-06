# ==============================================================================
# Choque Local e Emprego Setorial: DDD + FE + Event Study + Placebos (FULL)
# PADRÃO ACADÊMICO: SEM TÍTULOS INTERNOS | EXPORTAÇÃO 420 DPI
# ==============================================================================

# 1) Pacotes -------------------------------------------------------------------
source("config.R"); setwd(PROJECT_ROOT)

library(dplyr)
library(tidyr)
library(fixest)
library(ggplot2)
library(stringr)
library(broom)

# 2) Parâmetros ----------------------------------------------------------------
files <- c(
  "dados/RAIS_Painel_BA.csv",
  "dados/RAIS_Painel_CE.csv",
  "dados/RAIS_Painel_SP.csv"
)
data_sep <- ";"

treated_municipios <- c("Camaçari", "Horizonte", "Taubaté")
treat_sec_name     <- "AUTOMOBILÍSTICO"
treat_year         <- 2021
ref_year           <- treat_year - 1

try_windows <- list(
  c(4,3), c(3,2), c(2,2), c(2,1), c(1,1)
)

B_perm <- 2000
q_cut  <- 0.75
set.seed(123)

# 3) Leitura e Construção do Painel (PATCH COMPLETO) ---------------------------
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

# Diagnóstico de homônimos (Originalmente solicitado)
dup_name_ids <- panel_all %>% distinct(id_mun, id_municipio_nome) %>%
  count(id_municipio_nome, name = "n_ids") %>% filter(n_ids > 1) %>% arrange(desc(n_ids))
cat("Nomes com múltiplos IDs (homônimos):", nrow(dup_name_ids), "\n")
if(nrow(dup_name_ids) > 0) print(head(dup_name_ids, 20))

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
    treat_m  = as.integer(id_municipio_nome %in% treated_municipios | id_mun %in% treated_municipios),
    treat_s  = as.integer(secao == treat_sec_name),
    post     = as.integer(ano >= treat_year),
    ddd      = treat_m * treat_s * post,
    treat_ms = treat_m * treat_s,
    y_log    = log(emp + 1)
  )

# Diagnósticos de Suporte (Originalmente solicitado)
cat("IDs municipais:", n_distinct(panel_msy$id_mun), "| Anos:", paste(sort(unique(panel_msy$ano)), collapse=", "), "\n")
tmp_chk <- panel_msy %>% filter(treat_m == 1, treat_s == 1) %>% 
  group_by(ano) %>% summarise(emp_total = sum(emp, na.rm = TRUE), .groups="drop")
print(tmp_chk)

# 4) Estimação DDD + FE --------------------------------------------------------
m_ddd <- feols(y_log ~ ddd | id_mun^ano + secao^ano + id_mun^secao, 
               data = panel_msy, cluster = ~ id_mun, lean = TRUE)
summary(m_ddd)

# 5) Event Study e Exportação 420 DPI ------------------------------------------
es <- feols(y_log ~ i(ano, treat_ms, ref = ref_year) | id_mun^ano + secao^ano + id_mun^secao,
            data = panel_msy, cluster = ~ id_mun, lean = TRUE)
es_tbl <- broom::tidy(es, conf.int = TRUE) %>%
  filter(stringr::str_detect(term, "^ano::")) %>%
  mutate(Ano = as.integer(stringr::str_extract(term, "\\d{4}")))

p_event <- ggplot(es_tbl, aes(x = Ano, y = estimate)) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +
  geom_vline(xintercept = treat_year - 0.5, linetype = "dashed", color = "red") +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "steelblue", alpha = 0.2) +
  geom_line(color = "steelblue", size = 1) + geom_point(color = "steelblue", size = 2) +
  scale_x_continuous(breaks = sort(unique(es_tbl$Ano))) +
  labs(title = NULL, subtitle = NULL, x = "Ano", 
       y = paste0("Diferença em log do emprego (vs. ", ref_year, ")"),
       caption = paste0("Nota: Estimativas de Event Study. Municípios tratados: ", 
                        paste(treated_municipios, collapse=", "), ". Ref: ", ref_year, ".")) +
  theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1), plot.margin = margin(12, 28, 12, 12))

ggsave("outputs/EventStudy_420dpi.png", plot = p_event, width = 9, height = 6, dpi = 420)

# 6) Placebo Temporal (Busca de Melhor Janela) ---------------------------------
run_time_placebo <- function(py, pre_w, post_w){
  max_pre <- treat_year - 1
  d <- panel_msy %>% filter(ano >= py - pre_w, ano <= py + post_w, ano <= max_pre) %>%
    mutate(post_p = as.integer(ano >= py), ddd_p = treat_m * treat_s * post_p)
  if(sum(d$ddd_p, na.rm = TRUE) == 0) return(data.frame(py=py, beta=NA, ok=FALSE, motivo="sem_variacao"))
  dt <- d %>% filter(treat_m == 1)
  if(!(any(dt$treat_s==1 & dt$post_p==0) && any(dt$treat_s==1 & dt$post_p==1))) return(data.frame(py=py, beta=NA, ok=FALSE, motivo="falta_suporte"))
  
  out <- tryCatch({
    mod <- feols(y_log ~ ddd_p | id_mun^ano + secao^ano + id_mun^secao, data = d, cluster = ~ id_mun, lean = TRUE)
    data.frame(py = py, beta = unname(coef(mod)["ddd_p"]), ok = TRUE, motivo = "ok")
  }, error = function(e) data.frame(py=py, beta=NA, ok=FALSE, motivo="erro_estimacao"))
  out
}

best_tbl <- NULL; best_nok <- -Inf; best_w <- c(NA, NA)
for(wd in try_windows){
  pre_w <- wd[1]; post_w <- wd[2]
  placebo_years <- seq(min(panel_msy$ano) + pre_w, (treat_year - 1) - post_w)
  if(length(placebo_years) == 0) next
  tmp <- do.call(rbind, lapply(placebo_years, run_time_placebo, pre_w=pre_w, post_w=post_w))
  if(sum(tmp$ok) > best_nok){ best_nok <- sum(tmp$ok); best_tbl <- tmp; best_w <- wd }
  if(best_nok >= 4) break
}
cat("\nMelhor Janela Temporal (pre,post):", best_w[1], best_w[2], "\n")
print(best_tbl %>% filter(ok))

# 7) Placebo Espacial (Permutações de Fisher) ----------------------------------
perm_p_left_corrected <- function(betas, beta_real){
  betas <- betas[is.finite(betas)]
  if(length(betas) == 0) return(NA)
  (sum(betas <= beta_real) + 1) / (length(betas) + 1)
}

cand_pos <- panel_msy %>% filter(treat_s == 1, post == 1) %>% group_by(id_mun) %>%
  summarise(n_pos = n_distinct(ano), .groups = "drop") %>% filter(n_pos >= 2) %>% pull(id_mun)

auto_pre <- panel_msy %>% filter(treat_s == 1, ano <= ref_year) %>% group_by(id_mun) %>%
  summarise(emp_pre = sum(emp, na.rm = TRUE), .groups = "drop")

cut <- quantile(auto_pre$emp_pre, q_cut, na.rm = TRUE)
treated_ids <- unique(panel_msy$id_mun[panel_msy$treat_m == 1])
cand_pool <- setdiff(intersect(cand_pos, auto_pre$id_mun[auto_pre$emp_pre >= cut]), treated_ids)

K <- length(treated_ids)
fe_mt <- as.factor(interaction(panel_msy$id_mun, panel_msy$ano))
fe_st <- as.factor(interaction(panel_msy$secao, panel_msy$ano))
fe_ms <- as.factor(interaction(panel_msy$id_mun, panel_msy$secao))
y_res <- fixest::demean(panel_msy$y_log, f = list(fe_mt, fe_st, fe_ms))
w <- panel_msy$treat_s * panel_msy$post

beta_for_set <- function(mset){
  x_res <- fixest::demean(as.integer(panel_msy$id_mun %in% mset) * w, f = list(fe_mt, fe_st, fe_ms))
  den <- sum(x_res^2, na.rm = TRUE)
  if(is.na(den) || den == 0) return(NA_real_)
  sum(x_res * y_res, na.rm = TRUE) / den
}

beta_real_space <- beta_for_set(treated_ids)
betas_perm <- numeric(B_perm)
pb <- utils::txtProgressBar(min = 0, max = B_perm, style = 3)
for(j in 1:B_perm){
  betas_perm[j] <- beta_for_set(sample(cand_pool, K, replace = FALSE))
  if(j %% 200 == 0) utils::setTxtProgressBar(pb, j)
}
close(pb)

p_valor_perm <- perm_p_left_corrected(betas_perm, beta_real_space)

p_space <- ggplot(data.frame(beta = betas_perm[is.finite(betas_perm)]), aes(x = beta)) +
  geom_histogram(fill = "lightgrey", color = "grey40", bins = 35, alpha = 0.85) +
  geom_vline(xintercept = beta_real_space, color = "firebrick", linetype = "dashed", size = 1) +
  labs(title = NULL, subtitle = NULL, x = "Coeficientes Beta Placebo", y = "Frequência",
       caption = paste0("Permutação de Fisher (n=", B_perm, "). p-valor corrigido: ", 
                        format(p_valor_perm, scientific = FALSE), ". Beta Real: ", round(beta_real_space, 4))) +
  theme_classic() + theme(plot.margin = margin(18, 40, 18, 18)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))

ggsave("outputs/PlaceboEspacial_420dpi.png", plot = p_space, width = 9, height = 6, dpi = 420)

cat("\n[OK] Script finalizado. Figuras salvas com 420 DPI.\n")

