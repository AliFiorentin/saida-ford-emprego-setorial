import pandas as pd
from sklearn.linear_model import LinearRegression
import numpy as np

# --- INÍCIO DO CÓDIGO ---

# Defina o nome do seu arquivo de entrada (CSV anexado)
arquivo_entrada = 'bq-results-20260115-172219-1768497783562.csv'

# Defina o nome do arquivo de saída
arquivo_excel_saida = 'populacao_anual_com_previsao_2023.xlsx'

try:
    print("Lendo o arquivo de dados...")
    # Carrega o arquivo CSV original
    df = pd.read_csv(arquivo_entrada)

    # --- PREPARAÇÃO DOS DADOS ---
    # Pivota para ter anos como colunas para o cálculo da regressão
    df_pivot = df.pivot_table(index=['id_municipio', 'id_municipio_nome', 'sigla_uf', 'sigla_uf_nome'],
                              columns='ano',
                              values='populacao').reset_index()

    # --- PREVISÃO PARA 2023 ---

    # Anos para treinamento (2018 a 2022)
    anos_treino = np.array([2018, 2019, 2020, 2021, 2022]).reshape(-1, 1)
    cols_treino = [2018, 2019, 2020, 2021, 2022]

    previsoes_2023 = []

    print("Calculando previsões para 2023...")

    for index, row in df_pivot.iterrows():
        try:
            # Pega histórico
            populacao_historica = row[cols_treino].values.astype(float)

            # Pula se houver dados faltantes
            if np.isnan(populacao_historica).any():
                continue

            # Treina modelo
            modelo = LinearRegression()
            modelo.fit(anos_treino, populacao_historica)

            # Preve 2023
            populacao_prevista_2023 = modelo.predict([[2023]])

            # Adiciona à lista mantendo a estrutura original
            previsoes_2023.append({
                'ano': 2023,
                'sigla_uf': row['sigla_uf'],
                'sigla_uf_nome': row['sigla_uf_nome'],
                'id_municipio': row['id_municipio'],
                'id_municipio_nome': row['id_municipio_nome'],
                'populacao': int(round(populacao_prevista_2023[0]))
            })
        except Exception:
            continue

    # Cria DataFrame com as previsões
    df_2023 = pd.DataFrame(previsoes_2023)

    # Junta com os dados originais (acrescentando as linhas de 2023)
    df_final = pd.concat([df, df_2023], ignore_index=True)

    # Ordena para ficar organizado por município e ano
    df_final = df_final.sort_values(by=['id_municipio', 'ano'])

    # Salva o resultado
    df_final.to_excel(arquivo_excel_saida, index=False)

    print(f"Sucesso! Arquivo salvo como '{arquivo_excel_saida}'")
    print("\nExemplo final (últimas linhas):")
    print(df_final.tail())

except FileNotFoundError:
    print(f"ERRO: O arquivo '{arquivo_entrada}' não foi encontrado.")
except Exception as e:
    print(f"Ocorreu um erro inesperado: {e}")