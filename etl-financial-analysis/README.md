# Pipeline ETL e Análise Preditiva de Dados Financeiros

![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-2.0+-150458?logo=pandas&logoColor=white)
![SciPy](https://img.shields.io/badge/SciPy-1.10+-8CAAE6?logo=scipy&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?logo=jupyter&logoColor=white)

Pipeline ETL completo em Python integrando **3 fontes heterogêneas** (CSV, API REST, Excel) com detecção automática de anomalias via Z-score (limiar 3σ). Inclui regressão linear para projeção de receita (90 dias) e análise de séries temporais com média móvel — tudo documentado em 4 Jupyter Notebooks reproduzíveis.

---

## Objetivo

Demonstrar um fluxo ETL de ponta a ponta aplicado a dados financeiros, desde a ingestão de múltiplas fontes até análise preditiva e geração de visualizações prontas para decisão.

## Fontes de Dados

| Fonte | Formato | Descrição |
|-------|---------|-----------|
| Transações financeiras | CSV | 2.400 transações sintéticas (receitas e despesas) com anomalias injetadas |
| Cotações Ibovespa | API REST (yfinance) | Dados históricos de pregão (2022–2024) |
| Orçamento empresarial | Excel (.xlsx) | Receita e despesa planejada por categoria (36 meses) |

## Notebooks

| # | Notebook | Etapa | Destaques |
|---|----------|-------|-----------|
| 1 | `01_extract.ipynb` | **Extração** | Leitura de CSV, API yfinance e Excel → Parquet |
| 2 | `02_transform.ipynb` | **Transformação** | Padronização de tipos, limpeza, detecção de anomalias (Z-score 3σ) |
| 3 | `03_predict_regression.ipynb` | **Regressão** | Regressão linear com split treino/validação, projeção 90 dias, R², correlação com Ibovespa |
| 4 | `04_timeseries.ipynb` | **Séries Temporais** | Média móvel (3M/6M), bandas ±1σ, orçado vs. realizado, sazonalidade, dashboard resumo |

## Como Rodar Localmente

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/etl-financial-analysis.git
cd etl-financial-analysis

# 2. Crie e ative o ambiente virtual
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux/Mac

# 3. Instale as dependências
pip install -r requirements.txt

# 4. Gere os dados-fonte
python generate_source_data.py

# 5. Execute os notebooks em ordem
jupyter lab
```

## Estrutura do Projeto

```
etl-financial-analysis/
├── data/
│   ├── source/             # Arquivos originais (CSV, Excel)
│   ├── raw/                # Parquet brutos (gerados pelo notebook 01)
│   └── processed/          # Parquet limpos (gerados pelo notebook 02)
├── outputs/                # Gráficos gerados pelos notebooks
├── 01_extract.ipynb
├── 02_transform.ipynb
├── 03_predict_regression.ipynb
├── 04_timeseries.ipynb
├── generate_source_data.py # Gerador de dados sintéticos
├── requirements.txt
├── .gitignore
└── README.md
```

## Visualizações Geradas

Os notebooks geram automaticamente os seguintes gráficos em `outputs/`:

- **anomalias_zscore.png** — Distribuição de valores + scatter temporal com anomalias destacadas
- **projecao_receita.png** — Regressão linear com dados reais, projeção e banda de incerteza
- **correlacao_ibov.png** — Scatter de correlação Receita × Ibovespa
- **serie_temporal.png** — Receita mensal com média móvel 3M/6M e bandas ±1σ
- **receita_despesa.png** — Receita vs. despesa + saldo acumulado
- **orcado_vs_realizado.png** — Comparação orçamento planejado vs. real com desvio %
- **sazonalidade.png** — Receita média por mês do ano
- **dashboard_resumo.png** — Painel consolidado com 4 visualizações

## Tecnologias

- **Python 3.11+**
- **Pandas** — Manipulação e análise de dados
- **NumPy** — Operações numéricas
- **SciPy** — Z-score (detecção de anomalias), regressão linear
- **Matplotlib** — Visualizações
- **yfinance** — API REST para dados de mercado
- **openpyxl** — Leitura de arquivos Excel
- **Jupyter Notebook** — Documentação reproduzível

## Autor

**Rónison Ricardo** — Analista de Dados e BI  
[LinkedIn](https://www.linkedin.com/in/ronisonricardo) · [GitHub](https://github.com/ronisonricardo)
