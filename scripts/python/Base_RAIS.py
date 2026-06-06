import pandas as pd
import os
import glob
import unicodedata
import re
import gc

# --- 1. CONFIGURAÇÃO GLOBAL E DICIONÁRIOS ---

DICT_SECOES_NOMES = {
    'A': 'AGRICULTURA, PECUÁRIA, PRODUÇÃO FLORESTAL, PESCA E AQÜICULTURA',
    'B': 'INDÚSTRIAS EXTRATIVAS',
    'C': 'INDÚSTRIAS DE TRANSFORMAÇÃO',
    'C.A.': 'AUTOMOBILÍSTICO',  # Personalizado
    'D': 'ELETRICIDADE E GÁS',
    'E': 'ÁGUA, ESGOTO, ATIVIDADES DE GESTÃO DE RESÍDUOS E DESCONTAMINAÇÃO',
    'F': 'CONSTRUÇÃO',
    'G': 'COMÉRCIO; REPARAÇÃO DE VEÍCULOS AUTOMOTORES E MOTOCICLETAS',
    'G.A': 'AUTOMOBILÍSTICO',  # Personalizado
    'H': 'TRANSPORTE, ARMAZENAGEM E CORREIO',
    'I': 'ALOJAMENTO E ALIMENTAÇÃO',
    'J': 'INFORMAÇÃO E COMUNICAÇÃO',
    'K': 'ATIVIDADES FINANCEIRAS, DE SEGUROS E SERVIÇOS RELACIONADOS',
    'L': 'ATIVIDADES IMOBILIÁRIAS',
    'M': 'ATIVIDADES PROFISSIONAIS, CIENTÍFICAS E TÉCNICAS',
    'N': 'ATIVIDADES ADMINISTRATIVAS E SERVIÇOS COMPLEMENTARES',
    'O': 'ADMINISTRAÇÃO PÚBLICA, DEFESA E SEGURIDADE SOCIAL',
    'P': 'EDUCAÇÃO',
    'Q': 'SAÚDE HUMANA E SERVIÇOS SOCIAIS',
    'R': 'ARTES, CULTURA, ESPORTE E RECREAÇÃO',
    'S': 'OUTRAS ATIVIDADES DE SERVIÇOS',
    'T': 'SERVIÇOS DOMÉSTICOS',
    'U': 'ORGANISMOS INTERNACIONAIS E OUTRAS INSTITUIÇÕES EXTRATERRITORIAIS'
}


# --- 2. FUNÇÕES AUXILIARES ---

def normalizar_texto(texto):
    if not isinstance(texto, str):
        return str(texto)
    nfkd = unicodedata.normalize('NFKD', texto)
    return u"".join([c for c in nfkd if not unicodedata.combining(c)]).upper()


def limpar_cnae(valor):
    if pd.isna(valor):
        return ""
    s = str(valor)
    if s.endswith('.0'):
        s = s[:-2]
    return re.sub(r'[^0-9]', '', s)


def validar_arquivo(nome_arquivo):
    nome = nome_arquivo.upper()
    if re.match(r'^(CE|BA|SP)\d', nome):
        return True
    identificadores_especificos = ["RAIS_VINC_ID_NORDESTE", "RAIS_VINC_ID_SP"]
    if any(id_spec in nome for id_spec in identificadores_especificos):
        return True
    return False


def definir_uf(cod_municipio):
    if pd.isna(cod_municipio): return None
    prefixo = str(cod_municipio)[:2]
    if prefixo == '29': return 'BA'
    if prefixo == '23': return 'CE'
    if prefixo == '35': return 'SP'
    return 'OUTROS'


# --- 3. ETAPA 1: LEITURA E AGREGACAO DA RAIS (CHUNKS) ---

def processar_rais_chunks(lista_diretorios):
    dados_finais_consolidados = []

    # REMOVIDO: IDADE e SEXO TRABALHADOR
    colunas_necessarias = {
        'MUNICIPIO': 'Município',
        'VINCULO ATIVO 31/12': 'Vínculo Ativo 31/12',
        'CNAE 2.0 CLASSE': 'CNAE 2.0 Classe',
        'CNPJ / CEI': 'CNPJ / CEI'
    }

    TAMANHO_CHUNK = 200000

    print(f"--- ETAPA 1: Processamento RAIS (Agrupamento Simplificado) ---")

    for diretorio in lista_diretorios:
        print(f"Verificando diretório: {diretorio}")
        try:
            ano_diretorio = int(diretorio.split('RAIS ')[-1])
        except ValueError:
            ano_diretorio = 0

        arquivos_txt = glob.glob(os.path.join(diretorio, "*.txt"))

        for arquivo in arquivos_txt:
            nome_arquivo = os.path.basename(arquivo)

            if validar_arquivo(nome_arquivo):
                print(f"  > [LENDO]: {nome_arquivo}")
                try:
                    header_df = pd.read_csv(arquivo, sep=';', encoding='latin-1', nrows=1)
                    cols_originais = header_df.columns.tolist()
                    cols_use = []
                    rename_map = {}

                    for col in cols_originais:
                        col_norm = normalizar_texto(col)
                        if col_norm in colunas_necessarias:
                            rename_map[col] = colunas_necessarias[col_norm]
                            cols_use.append(col)
                        elif 'CNAE 2.0 CLASSE' in col_norm:
                            rename_map[col] = 'CNAE 2.0 Classe'
                            cols_use.append(col)
                        elif 'VINCULO ATIVO 31/12' in col_norm:
                            rename_map[col] = 'Vínculo Ativo 31/12'
                            cols_use.append(col)

                    if 'CNPJ / CEI' not in set(rename_map.values()):
                        print(f"    [PULADO] {nome_arquivo}: 'CNPJ / CEI' não encontrada.")
                        continue

                    chunks_do_arquivo = []
                    iterador_chunks = pd.read_csv(
                        arquivo, sep=';', encoding='latin-1', usecols=cols_use,
                        dtype=str, low_memory=False, chunksize=TAMANHO_CHUNK
                    )

                    for df_chunk in iterador_chunks:
                        df_chunk.rename(columns=rename_map, inplace=True)

                        if 'Vínculo Ativo 31/12' in df_chunk.columns:
                            df_chunk['Vínculo Ativo 31/12'] = pd.to_numeric(df_chunk['Vínculo Ativo 31/12'],
                                                                            errors='coerce')
                            df_chunk = df_chunk[df_chunk['Vínculo Ativo 31/12'] == 1].copy()

                        if df_chunk.empty: continue

                        df_chunk['Ano'] = ano_diretorio
                        df_chunk['UF'] = df_chunk['Município'].apply(definir_uf)

                        df_chunk = df_chunk[df_chunk['UF'].isin(['CE', 'BA', 'SP'])].copy()
                        if df_chunk.empty: continue

                        # Agrupamento sem Faixa Etária e Sexo
                        group_cols = ['Município', 'Ano', 'CNAE 2.0 Classe', 'UF']
                        cols_presentes = [c for c in group_cols if c in df_chunk.columns]

                        df_agg_parcial = df_chunk.groupby(cols_presentes).agg(
                            Empregados=('CNPJ / CEI', 'count'),
                            Empresas=('CNPJ / CEI', 'nunique')
                        ).reset_index()

                        chunks_do_arquivo.append(df_agg_parcial)
                        del df_chunk, df_agg_parcial

                    if chunks_do_arquivo:
                        df_total = pd.concat(chunks_do_arquivo, ignore_index=True)
                        cols_final = [c for c in ['Município', 'Ano', 'CNAE 2.0 Classe', 'UF'] if c in df_total.columns]
                        df_total = df_total.groupby(cols_final).agg(
                            {'Empregados': 'sum', 'Empresas': 'sum'}).reset_index()

                        dados_finais_consolidados.append(df_total)
                        del df_total, chunks_do_arquivo
                        gc.collect()

                except Exception as e:
                    print(f"    ERRO CRÍTICO em {nome_arquivo}: {e}")

    if dados_finais_consolidados:
        print("Consolidando todos os arquivos da RAIS...")
        df_final = pd.concat(dados_finais_consolidados, ignore_index=True)
        cols_final = [c for c in ['Município', 'Ano', 'CNAE 2.0 Classe', 'UF'] if c in df_final.columns]
        df_final = df_final.groupby(cols_final).agg({'Empregados': 'sum', 'Empresas': 'sum'}).reset_index()
        return df_final
    else:
        return pd.DataFrame()


# --- 4. ETAPA 2: MAPEAMENTO DE SETORES ECONÔMICOS ---

def aplicar_mapeamento_cnae(df_rais, caminho_mapa):
    print("\n--- ETAPA 2: Mapeamento de Setores (CNAE -> Seção) ---")

    if df_rais.empty:
        print("DataFrame da RAIS está vazio. Encerrando.")
        return pd.DataFrame()

    if not os.path.exists(caminho_mapa):
        print(f"ERRO: Arquivo '{caminho_mapa}' não encontrado.")
        return pd.DataFrame()

    print(f"Carregando arquivo de mapeamento: {caminho_mapa}...")
    try:
        df_mapa = pd.read_excel(caminho_mapa, dtype=str)
    except Exception as e:
        print(f"ERRO FATAL ao ler arquivo Excel: {e}")
        return pd.DataFrame()

    df_mapa.columns = [c.strip().upper() for c in df_mapa.columns]
    col_classe = next((c for c in df_mapa.columns if 'CLASSE' in c), None)
    col_secao = next((c for c in df_mapa.columns if 'SEÇÃO' in c or 'SECAO' in c), None)

    if not col_classe or not col_secao:
        print(f"Colunas CLASSE ou SEÇÃO não encontradas. Colunas: {df_mapa.columns.tolist()}")
        return pd.DataFrame()

    print("Criando índice de CNAE...")
    df_mapa['CNAE_Clean'] = df_mapa[col_classe].apply(limpar_cnae)
    df_mapa = df_mapa.drop_duplicates(subset=['CNAE_Clean'])
    mapa_secoes = dict(zip(df_mapa['CNAE_Clean'], df_mapa[col_secao]))

    print("Aplicando regras de substituição...")
    df_rais['CNAE_Clean'] = df_rais['CNAE 2.0 Classe'].apply(limpar_cnae)

    def obter_secao(cnae):
        if cnae.startswith('29'): return 'C.A.'
        if cnae.startswith('45'): return 'G.A'
        return mapa_secoes.get(cnae, 'NÃO ENCONTRADO')

    df_rais['Cod_Secao'] = df_rais['CNAE_Clean'].apply(obter_secao)
    df_rais['Seção'] = df_rais['Cod_Secao'].map(DICT_SECOES_NOMES)
    df_rais['Seção'] = df_rais['Seção'].fillna('OUTROS / NÃO IDENTIFICADO')

    print("Reagrupando dados finais (Município, Ano, Seção, UF)...")

    # Agrupamento final solicitado
    colunas_finais = ['Município', 'Ano', 'Seção', 'UF']
    cols_existentes = [c for c in colunas_finais if c in df_rais.columns]

    df_final_setores = df_rais.groupby(cols_existentes).agg({
        'Empregados': 'sum',
        'Empresas': 'sum'
    }).reset_index()

    return df_final_setores


# --- 5. EXECUÇÃO PRINCIPAL ---

DIRETORIOS_RAIS = [
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2021",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2022",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2023",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2014",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2015",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2016",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2017",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2018",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2019",
    r"D:\RAIS Vínculos 2014 - 2023\RAIS 2020"
]

CAMINHO_ARQUIVO_CNAE = "dados/CNAE20.xlsx"

if __name__ == "__main__":
    df_intermediario = processar_rais_chunks(DIRETORIOS_RAIS)

    if not df_intermediario.empty:
        df_resultado_final = aplicar_mapeamento_cnae(df_intermediario, CAMINHO_ARQUIVO_CNAE)

        if not df_resultado_final.empty:
            nome_arquivo_saida = "dados/RAIS_Final_Sem_FaixaEtaria.csv"
            df_resultado_final.to_csv(nome_arquivo_saida, index=False, sep=';', encoding='utf-8-sig')

            print("\n" + "=" * 50)
            print(f"SUCESSO! Arquivo gerado: {os.path.abspath(nome_arquivo_saida)}")
            print("=" * 50)
            print(df_resultado_final.head())
        else:
            print("Erro na etapa de mapeamento de setores.")
    else:
        print("Nenhum dado foi extraído da RAIS.")