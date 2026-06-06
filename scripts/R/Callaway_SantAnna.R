setwd("C:/Users/Administrator/Documents/Shashinha")
library(dplyr); library(tidyr); library(did); library(ggplot2)

files <- c("dados/RAIS_Painel_BA.csv","dados/RAIS_Painel_CE.csv","dados/RAIS_Painel_SP.csv")
treated_codes <- c("290570","355410","230523")
treat_sec_name <- "AUTOMOBILÍSTICO"
treat_year <- 2021

read_one <- function(path) {
  read.csv(path, sep=";", stringsAsFactors=FALSE, colClasses="character") %>%
    mutate(cod_municipio=as.character(cod_municipio), secao=as.character(secao),
           ano=as.integer(ano), empregados=suppressWarnings(as.numeric(empregados)))
}
panel_all <- bind_rows(lapply(files, read_one))

panel_auto <- panel_all %>%
  filter(secao == treat_sec_name) %>%
  group_by(cod_municipio, ano) %>%
  summarise(emp=sum(empregados, na.rm=TRUE), .groups="drop")

years_all <- sort(unique(panel_auto$ano))
mun_names <- panel_all %>% distinct(cod_municipio, id_municipio_nome)
all_muns <- sort(unique(panel_auto$cod_municipio))
id_map <- data.frame(cod_municipio=all_muns, id_num=seq_along(all_muns))

panel_auto <- panel_auto %>%
  tidyr::complete(cod_municipio, ano=years_all, fill=list(emp=0)) %>%
  left_join(mun_names, by="cod_municipio") %>%
  left_join(id_map, by="cod_municipio") %>%
  mutate(
    treat_m = as.integer(cod_municipio %in% treated_codes),
    g       = ifelse(treat_m==1, treat_year, 0),  # 0 = never treated
    y_log   = log(emp+1)
  )

cat(sprintf("Municípios: %d (tratados: %d, controles: %d)\n",
            n_distinct(panel_auto$cod_municipio),
            sum(panel_auto$treat_m==1 & panel_auto$ano==min(panel_auto$ano)),
            sum(panel_auto$treat_m==0 & panel_auto$ano==min(panel_auto$ano))))

set.seed(42)
cat("=== Callaway & Sant'Anna att_gt ===\n")
cs_out <- tryCatch(
  att_gt(yname="y_log", tname="ano", idname="id_num", gname="g",
         data=panel_auto, control_group="nevertreated",
         base_period="universal", anticipation=0,
         bstrap=TRUE, biters=999, pl=FALSE),
  error=function(e){cat(sprintf("ERRO att_gt: %s\n", conditionMessage(e))); NULL}
)

if(!is.null(cs_out)){
  print(summary(cs_out))

  cs_dyn  <- aggte(cs_out, type="dynamic")
  cs_simp <- aggte(cs_out, type="simple")
  cat("\n=== Efeito Dinâmico (Event Study C&S) ===\n"); print(summary(cs_dyn))
  cat("\n=== ATT Agregado Simples ===\n"); print(summary(cs_simp))

  p_cs <- ggdid(cs_dyn) +
    labs(caption="Callaway & Sant'Anna (2021). Setor Automotivo. Controle: never-treated.") +
    theme_minimal()
  ggsave("outputs/CallawaySantAnna_Event_420dpi.png", plot=p_cs, width=9, height=6, dpi=420)
  cat("\n[OK] Callaway_SantAnna.R concluído.\n")
} else {
  cat("[FALHA] att_gt não convergiu — verifique o log.\n")
}

