/* ====================================================================
   SCRIPT: PREPARAÇÃO COMPLETA + EXPORTAÇÃO ESTADUAL
   OBJETIVO: Preparação simples e exportação por UF
   ==================================================================== */

clear all
set more off

// Carregar configuração local (caminhos do projeto)
// Copie config.example.do para config.do na raiz e ajuste o caminho
do "config.do"

// 1. IMPORTAÇÃO E LIMPEZA
// --------------------------------------------------------------------
import delimited "$PROJECT_ROOT\dados\RAIS_Final_Sem_FaixaEtaria.csv", delimiter(";") encoding("utf-8") case(preserve) clear

// Renomear para facilitar
rename Município cod_municipio
rename Seção     secao
rename Ano       ano
rename UF        uf
rename Empregados empregados

// Garantir numérico
capture destring cod_municipio, replace force

// Padronizar Strings (Maiúsculo e sem espaços)
replace secao = ustrupper(strtrim(secao))
replace uf = ustrupper(strtrim(uf))


// 3. DEFINIR A VARIÁVEL INDICADORA (GVAR = 1)
// --------------------------------------------------------------------
gen gvar = 0

// A) COORTE 2021: Camaçari (BA) e Taubaté (SP) - Ford
replace gvar = 1 if inlist(cod_municipio, 290570, 355410) & ano >= 2021

// B) COORTE 2022: Horizonte (CE) - Troller
replace gvar = 1 if cod_municipio == 230523 & ano >= 2022

// 4. EXPORTAÇÃO DOS ARQUIVOS SEPARADOS
// --------------------------------------------------------------------
local outpath "$PROJECT_ROOT\dados"

// Exportar CEARA
export delimited using "`outpath'\RAIS_Painel_CE.csv" if uf == "CE", delimiter(";") replace
display "Arquivo CE exportado."

// Exportar BAHIA
export delimited using "`outpath'\RAIS_Painel_BA.csv" if uf == "BA", delimiter(";") replace
display "Arquivo BA exportado."

// Exportar SAO PAULO
export delimited using "`outpath'\RAIS_Painel_SP.csv" if uf == "SP", delimiter(";") replace
display "Arquivo SP exportado."
