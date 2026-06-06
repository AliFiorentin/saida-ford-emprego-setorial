setwd("C:/Users/Administrator/Documents/Shashinha")
library(dplyr); library(tidyr); library(synthdid); library(ggplot2)

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
panel_auto <- panel_auto %>%
  tidyr::complete(cod_municipio, ano=years_all, fill=list(emp=0)) %>%
  mutate(treat_m=as.integer(cod_municipio %in% treated_codes),
         y_log=log(emp+1))

# Build balanced matrix: controls first, treated last, years sorted ascending
ctrl_ids <- sort(unique(panel_auto$cod_municipio[panel_auto$treat_m==0]))
trt_ids  <- sort(unique(panel_auto$cod_municipio[panel_auto$treat_m==1]))
all_ids  <- c(ctrl_ids, trt_ids)
years_sorted <- sort(unique(panel_auto$ano))

Y_wide <- panel_auto %>%
  select(cod_municipio, ano, y_log) %>%
  pivot_wider(names_from=ano, values_from=y_log, names_sort=TRUE) %>%
  arrange(match(cod_municipio, all_ids)) %>%
  select(-cod_municipio) %>%
  as.matrix()

N0 <- length(ctrl_ids)
T0 <- sum(years_sorted < treat_year)

cat(sprintf("Matriz Y: %d unidades x %d períodos | N0=%d controles | T0=%d pré-trat.\n",
            nrow(Y_wide), ncol(Y_wide), N0, T0))

# Check for NAs
if(any(is.na(Y_wide))){
  cat(sprintf("AVISO: %d NAs na matriz. Imputando com 0.\n", sum(is.na(Y_wide))))
  Y_wide[is.na(Y_wide)] <- 0
}

set.seed(42)
cat("=== SDID (Synthetic Difference-in-Differences) ===\n")
tau_sdid <- tryCatch(
  synthdid_estimate(Y_wide, N0, T0),
  error=function(e){cat(sprintf("ERRO synthdid: %s\n", conditionMessage(e))); NULL}
)

if(!is.null(tau_sdid)){
  cat(sprintf("SDID tau = %.4f\n", as.numeric(tau_sdid)))
  cat(sprintf("Efeito estimado: %.2f%%\n", 100*(exp(as.numeric(tau_sdid))-1)))

  se_sdid <- tryCatch(
    sqrt(vcov(tau_sdid, method="jackknife")),
    error=function(e){cat(sprintf("SE jackknife falhou: %s\n", conditionMessage(e))); NA}
  )
  if(!is.na(se_sdid)) cat(sprintf("SE (jackknife) = %.4f | t = %.3f\n",
                                    se_sdid, as.numeric(tau_sdid)/se_sdid))

  p_sdid <- plot(tau_sdid)
  ggsave("outputs/SDID_auto_420dpi.png", plot=p_sdid, width=9, height=6, dpi=420)
  cat("\n[OK] SDID.R concluído.\n")
} else {
  cat("[FALHA] synthdid_estimate não convergiu — verifique log.\n")
}

