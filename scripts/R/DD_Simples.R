setwd("C:/Users/Administrator/Documents/Shashinha")
library(dplyr); library(tidyr); library(fixest); library(ggplot2); library(broom); library(stringr)

files <- c("dados/RAIS_Painel_BA.csv","dados/RAIS_Painel_CE.csv","dados/RAIS_Painel_SP.csv")
treated_codes <- c("290570","355410","230523")
treat_sec_name <- "AUTOMOBILÍSTICO"
treat_year <- 2021; ref_year <- 2020

read_one <- function(path) {
  read.csv(path, sep=";", stringsAsFactors=FALSE, colClasses="character") %>%
    mutate(cod_municipio=as.character(cod_municipio),
           secao=as.character(secao),
           ano=as.integer(ano),
           empregados=suppressWarnings(as.numeric(empregados)))
}
panel_all <- bind_rows(lapply(files, read_one))

# Automotive subpanel
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
    post    = as.integer(ano >= treat_year),
    y_log   = log(emp + 1)
  )

cat("=== DD Simples (feols: treat_m:post | mun + ano) ===\n")
m_dd <- feols(y_log ~ treat_m:post | cod_municipio + ano,
              data=panel_auto, cluster=~cod_municipio)
print(summary(m_dd))
cat(sprintf("\n%% efeito DD: %.2f%%\n", 100*(exp(coef(m_dd)["treat_m:post"])-1)))

# Event study DD
cat("\n=== Event Study DD (ref=2020) ===\n")
m_dd_es <- feols(y_log ~ i(ano, treat_m, ref=ref_year) | cod_municipio + ano,
                 data=panel_auto, cluster=~cod_municipio)
print(summary(m_dd_es))

es_tbl <- broom::tidy(m_dd_es, conf.int=TRUE) %>%
  filter(str_detect(term,"^ano::")) %>%
  mutate(Ano=as.integer(str_extract(term,"\\d{4}")))

p_dd <- ggplot(es_tbl, aes(x=Ano, y=estimate)) +
  geom_hline(yintercept=0, color="black", linewidth=0.5) +
  geom_vline(xintercept=treat_year-0.5, linetype="dashed", color="red") +
  geom_ribbon(aes(ymin=conf.low, ymax=conf.high), fill="steelblue", alpha=0.2) +
  geom_line(color="steelblue", linewidth=1) + geom_point(color="steelblue", size=2) +
  scale_x_continuous(breaks=sort(unique(es_tbl$Ano))) +
  labs(x="Ano", y=paste0("Coef. DD (vs. ",ref_year,")"),
       caption=paste0("DD Simples — Setor Automotivo. Tratados: Camaçari, Taubaté, Horizonte. Ref: ",ref_year,".")) +
  theme_minimal() + theme(axis.text.x=element_text(angle=45,hjust=1), plot.margin=margin(12,28,12,12))
ggsave("outputs/DD_Simples_Event_420dpi.png", plot=p_dd, width=9, height=6, dpi=420)

cat("\n[OK] DD_Simples.R concluído.\n")

