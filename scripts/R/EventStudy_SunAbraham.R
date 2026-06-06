source("config.R"); setwd(PROJECT_ROOT)
library(dplyr); library(tidyr); library(fixest); library(ggplot2); library(broom); library(stringr)

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

panel_auto <- panel_auto %>%
  tidyr::complete(cod_municipio, ano=years_all, fill=list(emp=0)) %>%
  left_join(mun_names, by="cod_municipio") %>%
  mutate(
    treat_m = as.integer(cod_municipio %in% treated_codes),
    cohort  = ifelse(treat_m==1, treat_year, Inf),
    y_log   = log(emp+1)
  )

cat("=== Sun & Abraham (sunab via fixest) ===\n")
m_sa <- feols(y_log ~ sunab(cohort, ano) | cod_municipio + ano,
              data=panel_auto, cluster=~cod_municipio)
print(summary(m_sa))

# Aggregate ATT for sunab model
agg_att <- tryCatch(
  aggregate(m_sa, agg="ATT"),
  error=function(e) {
    cat(sprintf("aggregate(agg='ATT') falhou: %s\n", conditionMessage(e)))
    NULL
  }
)
if (!is.null(agg_att)) {
  cat("=== ATT Agregado (Sun & Abraham) ===\n")
  print(agg_att)
}

sa_tbl <- broom::tidy(m_sa, conf.int=TRUE)
print(sa_tbl)

# The sunab terms are relative periods (e.g. ano::-7, ano::0, ano::1, ano::2)
# Extract the relative period number
es_sa <- sa_tbl %>%
  mutate(rel_period = as.integer(str_extract(term, "-?\\d+"))) %>%
  filter(!is.na(rel_period)) %>%
  mutate(period = treat_year + rel_period) %>%
  arrange(period)

if(nrow(es_sa)>0){
  p_sa <- ggplot(es_sa, aes(x=period, y=estimate)) +
    geom_hline(yintercept=0, color="black", linewidth=0.5) +
    geom_vline(xintercept=treat_year-0.5, linetype="dashed", color="red") +
    geom_ribbon(aes(ymin=conf.low, ymax=conf.high), fill="darkorange", alpha=0.2) +
    geom_line(color="darkorange", linewidth=1) + geom_point(color="darkorange", size=2) +
    scale_x_continuous(breaks=sort(unique(es_sa$period))) +
    labs(x="Ano", y="Coeficiente Sun & Abraham",
         caption="Estimador Sun & Abraham (2021). Setor Automotivo. Controles: never-treated.") +
    theme_minimal() + theme(axis.text.x=element_text(angle=45,hjust=1), plot.margin=margin(12,28,12,12))
  ggsave("outputs/SunAbraham_Event_420dpi.png", plot=p_sa, width=9, height=6, dpi=420)
}
cat("\n[OK] EventStudy_SunAbraham.R concluído.\n")


