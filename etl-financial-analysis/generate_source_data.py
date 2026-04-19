"""
Generate synthetic source data for the ETL Financial Analysis project.
Creates:
  - data/source/personal_finance.csv  (CSV source)
  - data/source/orcamento.xlsx        (Excel source)

Run once before executing the notebooks.
"""

import os
import random
from datetime import datetime, timedelta

import numpy as np
import pandas as pd

SEED = 42
random.seed(SEED)
np.random.seed(SEED)

os.makedirs("data/source", exist_ok=True)

# ──────────────────────────────────────────────
# 1. Synthetic personal-finance CSV
# ──────────────────────────────────────────────
categories_income = ["Salário", "Freelance", "Rendimentos", "Bônus"]
categories_expense = [
    "Alimentação", "Transporte", "Moradia", "Saúde",
    "Educação", "Lazer", "Assinaturas", "Vestuário",
    "Impostos", "Manutenção",
]

rows = []
start = datetime(2022, 1, 1)
end = datetime(2024, 12, 31)
n_days = (end - start).days

for _ in range(2400):
    date = start + timedelta(days=random.randint(0, n_days))
    is_income = random.random() < 0.25

    if is_income:
        cat = random.choice(categories_income)
        amount = round(random.gauss(4500, 1800), 2)
        amount = max(amount, 200)
        tx_type = "receita"
    else:
        cat = random.choice(categories_expense)
        amount = round(random.gauss(350, 250), 2)
        amount = max(amount, 5)
        tx_type = "despesa"

    rows.append(
        {
            "date": date.strftime("%Y-%m-%d"),
            "category": cat,
            "type": tx_type,
            "amount": amount,
            "description": f"{cat} — transação automática",
            "payment_method": random.choice(
                ["Pix", "Cartão de Crédito", "Débito", "Boleto", "Transferência"]
            ),
        }
    )

# Inject ~15 anomalies (very high or negative values)
for i in random.sample(range(len(rows)), 15):
    if random.random() < 0.5:
        rows[i]["amount"] = round(random.uniform(15000, 35000), 2)
    else:
        rows[i]["amount"] = round(random.uniform(-5000, -500), 2)
    rows[i]["description"] += " [ANOMALIA INJETADA]"

df_csv = pd.DataFrame(rows)
df_csv = df_csv.sample(frac=1, random_state=SEED).reset_index(drop=True)
df_csv.to_csv("data/source/personal_finance.csv", index=False)
print(f"✔ personal_finance.csv — {len(df_csv)} registros")

# ──────────────────────────────────────────────
# 2. Excel budget file (Orçamento)
# ──────────────────────────────────────────────
months = pd.date_range("2022-01", "2024-12", freq="MS")
budget_rows = []

for m in months:
    base_revenue = 12000 + np.random.normal(0, 1500)
    trend = (m.year - 2022) * 800 + m.month * 50
    receita = round(max(base_revenue + trend, 3000), 2)

    for cat in ["Operacional", "Marketing", "Pessoal", "Infraestrutura"]:
        pct = {"Operacional": 0.35, "Marketing": 0.15, "Pessoal": 0.38, "Infraestrutura": 0.12}[cat]
        despesa = round(receita * pct * np.random.uniform(0.85, 1.15), 2)
        budget_rows.append(
            {
                "mes": m.strftime("%Y-%m"),
                "categoria": cat,
                "receita": receita,
                "despesa": despesa,
                "saldo": round(receita - despesa, 2),
            }
        )

df_xl = pd.DataFrame(budget_rows)
with pd.ExcelWriter("data/source/orcamento.xlsx", engine="openpyxl") as writer:
    df_xl.to_excel(writer, sheet_name="Dados", index=False)
print(f"✔ orcamento.xlsx — {len(df_xl)} linhas")

print("\n✅ Dados-fonte gerados com sucesso em data/source/")
