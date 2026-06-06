import pandas as pd
from sklearn.linear_model import LinearRegression
import numpy as np

# --- INÍCIO DO CÓDIGO ---

# Nome do arquivo de entrada (CSV de PIB)
arquivo_entrada = 'dados/PIB.csv'

# Nome do arquivo de saída
arquivo_excel_saida = 'dados/PIB Ajustado.xlsx'

try:
    print("Lendo arquivo de dados...")
    df = pd.read_csv(arquivo_entrada)

    # Prepara os dados (Pivot)
    df_pivot = df.pivot_table(index=['id_municipio', 'id_municipio_nome'],
                              columns='ano',
                              values='pib').reset_index()

    # Define anos de treino (últimos 5 anos disponíveis: 2017-2021)
    anos_treino = np.array([2017, 2018, 2019, 2020, 2021]).reshape(-1, 1)
    cols_treino = [2017, 2018, 2019, 2020, 2021]

    novas_linhas = []

    print("Calculando previsões para 2022 e 2023...")

    for index, row in df_pivot.iterrows():
        try:
            y = row[cols_treino].values.astype(float)

            # Pula se houver dados faltantes
            if np.isnan(y).any():
                continue

            # Treina o modelo
            modelo = LinearRegression()
            modelo.fit(anos_treino, y)

            # Previsões
            pib_2022 = modelo.predict([[2022]])[0]
            pib_2023 = modelo.predict([[2023]])[0]

            # Adiciona 2022
            novas_linhas.append({
                'id_municipio': row['id_municipio'],
                'id_municipio_nome': row['id_municipio_nome'],
                'ano': 2022,
                'pib': int(round(pib_2022))
            })

            # Adiciona 2023
            novas_linhas.append({
                'id_municipio': row['id_municipio'],
                'id_municipio_nome': row['id_municipio_nome'],
                'ano': 2023,
                'pib': int(round(pib_2023))
            })

        except Exception:
            continue

    # Cria DataFrame com as previsões
    df_novos = pd.DataFrame(novas_linhas)

    # Concatena com os dados originais
    df_final = pd.concat([df, df_novos], ignore_index=True)

    # Ordena
    df_final = df_final.sort_values(by=['id_municipio', 'ano'])

    # Salva
    df_final.to_excel(arquivo_excel_saida, index=False)

    print(f"Sucesso! Arquivo salvo como '{arquivo_excel_saida}'")
    print(df_final.tail())

except FileNotFoundError:
    print(f"ERRO: O arquivo '{arquivo_entrada}' não foi encontrado.")
except Exception as e:
    print(f"Ocorreu um erro inesperado: {e}")