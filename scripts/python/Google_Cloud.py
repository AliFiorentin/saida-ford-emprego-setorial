import basedosdados as bd
import pandas as pd
import os

# --- CONFIGURAÇÃO OBRIGATÓRIA ---
# Substitua pelo ID do seu projeto no Google Cloud
# Se não tiver um, crie em: https://console.cloud.google.com/projectselector2/home/dashboard
BILLING_PROJECT_ID = "caged-480722"

# Diretório para salvar os arquivos
OUTPUT_DIR = "dados_rais"
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)


def download_rais_data():
    print(f"Iniciando processo de download. Arquivos serão salvos em: {OUTPUT_DIR}")

    # Loop para baixar ano a ano (evita estourar a memória RAM)
    for ano in range(2013, 2024):
        print(f"\n--- Processando ano: {ano} ---")

        # A query é a mesma que você forneceu, mas adaptada para f-string
        # Note que filtrei 'dados.ano = {ano}' para baixar fatiado
        query = f"""
        SELECT
            dados.ano,
            id_municipio,
            dados.sigla_uf,
            dados.cnae_2_subclasse,
            dados.vinculo_ativo_3112,
            dados.valor_remuneracao_media,
            dados.grau_instrucao_apos_2005,
            dados.faixa_etaria,
            dados.sexo,

            -- Flags de identificação de CNAE
            CAST((LEFT(dados.cnae_2_subclasse, 2) = '29') AS INT64) AS is_automotive_manufacturing,
            CAST((LEFT(dados.cnae_2_subclasse, 2) BETWEEN '10' AND '33') AS INT64) AS is_manufacturing,
            CAST((LEFT(dados.cnae_2_subclasse, 2) = '47') AS INT64) AS is_commerce,
            CAST(((LEFT(dados.cnae_2_subclasse, 2) BETWEEN '68' AND '82') OR (LEFT(dados.cnae_2_subclasse, 2) BETWEEN '84' AND '96')) AS INT64) AS is_services

        FROM
            `basedosdados.br_me_rais.microdados_vinculos` AS dados
        WHERE
            dados.ano = {ano}
            AND dados.vinculo_ativo_3112 = '1'
            AND dados.sigla_uf IN ('BA', 'SP', 'CE')
            -- Filtro de consistência UF/Município
            AND (
                (dados.sigla_uf = 'BA' AND LEFT(dados.id_municipio, 2) = '29') OR
                (dados.sigla_uf = 'SP' AND LEFT(dados.id_municipio, 2) = '35') OR
                (dados.sigla_uf = 'CE' AND LEFT(dados.id_municipio, 2) = '23')
            )
        """

        try:
            print(f"Baixando dados do BigQuery para {ano}...")

            # Executa a query e retorna um DataFrame do Pandas
            df = bd.read_sql(query, billing_project_id=BILLING_PROJECT_ID)

            if df.empty:
                print(f"Aviso: Nenhum dado encontrado para o ano {ano}.")
                continue

            # Define o caminho do arquivo
            # Recomendo Parquet para arquivos grandes (preserva tipos de dados e é menor)
            file_path = os.path.join(OUTPUT_DIR, f"rais_vinculos_{ano}.parquet")

            # Salva em Parquet
            df.to_parquet(file_path, index=False)

            # Se preferir CSV (descomente as linhas abaixo e comente as do parquet):
            # file_path = os.path.join(OUTPUT_DIR, f"rais_vinculos_{ano}.csv")
            # df.to_csv(file_path, index=False, sep=';', decimal=',')

            print(f"Sucesso! Arquivo salvo em: {file_path}")
            print(f"Registros baixados: {len(df)}")

            # Limpa memória
            del df

        except Exception as e:
            print(f"Erro ao processar o ano {ano}: {e}")

    print("\nProcesso finalizado.")


if __name__ == "__main__":
    download_rais_data()