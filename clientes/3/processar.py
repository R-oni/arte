#!/usr/bin/env python3
"""
Processador de dados para Cliente #3 (Bella Vista Restaurant)

Lê CSVs de /Restaurant Orders/ e gera dados.json para o dashboard.
Executar: python clientes/3/processar.py
"""

import pandas as pd
import json
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
RESTAURANT_DIR = SCRIPT_DIR.parent.parent / "Restaurant Orders"
DADOS_JSON = SCRIPT_DIR / "dados.json"


def get_period(hour):
    if 11 <= hour <= 14:
        return "Almoço (11h-14h)"
    elif 15 <= hour <= 17:
        return "Tarde (15h-17h)"
    elif 18 <= hour <= 21:
        return "Jantar (18h-21h)"
    else:
        return "Noite (22h+)"


def processar():
    print(f"[INFO] Lendo dados de: {RESTAURANT_DIR}")

    menu = pd.read_csv(RESTAURANT_DIR / "menu_items.csv")
    orders = pd.read_csv(RESTAURANT_DIR / "order_details.csv")

    print(f"[INFO] {len(menu)} itens no cardápio, {len(orders)} linhas de pedidos")

    # Join pedidos com cardápio
    df = orders.merge(
        menu[["menu_item_id", "item_name", "category", "price"]],
        left_on="item_id",
        right_on="menu_item_id",
        how="left",
    )
    df = df.dropna(subset=["price"])

    # Parsear data e hora
    df["date"] = pd.to_datetime(df["order_date"], format="%m/%d/%y")
    df["month_num"] = df["date"].dt.month
    df["hour"] = pd.to_datetime(df["order_time"], format="%I:%M:%S %p").dt.hour
    df["period"] = df["hour"].apply(get_period)

    mes_map = {1: "janeiro", 2: "fevereiro", 3: "março"}

    dados_por_mes = {}
    dados_lista = []

    for month_num in sorted(mes_map.keys()):
        month_name = mes_map[month_num]
        df_mes = df[df["month_num"] == month_num].copy()

        if df_mes.empty:
            continue

        faturamento = float(df_mes["price"].sum())
        pedidos = int(df_mes["order_id"].nunique())
        itens_total = len(df_mes)

        # Top pratos por receita (com contagem para ticket médio)
        top_rev = (
            df_mes.groupby("item_name")["price"]
            .agg(["sum", "count"])
            .reset_index()
            .rename(columns={"item_name": "nome", "sum": "faturamento", "count": "count"})
            .sort_values("faturamento", ascending=False)
        )
        servicos = [
            {
                "nome": row["nome"],
                "faturamento": round(float(row["faturamento"]), 2),
                "count": int(row["count"]),
            }
            for _, row in top_rev.iterrows()
        ]

        # Receita por categoria culinária
        cat_rev = (
            df_mes.groupby("category")["price"]
            .sum()
            .sort_values(ascending=False)
            .reset_index()
        )
        formas_pagamento = [
            {"nome": row["category"], "valor": round(float(row["price"]), 2)}
            for _, row in cat_rev.iterrows()
        ]

        # Pedidos por período do dia
        period_orders = (
            df_mes.groupby("period")["order_id"]
            .nunique()
            .reset_index()
            .rename(columns={"order_id": "valor"})
            .sort_values("valor", ascending=False)
        )
        period_order_map = {
            "Almoço (11h-14h)": 0,
            "Tarde (15h-17h)": 1,
            "Jantar (18h-21h)": 2,
            "Noite (22h+)": 3,
        }
        period_orders["sort_key"] = period_orders["period"].map(period_order_map)
        period_orders = period_orders.sort_values("sort_key")
        pedidos_hora = [
            {"nome": row["period"], "valor": int(row["valor"])}
            for _, row in period_orders.iterrows()
        ]

        # Pratos mais pedidos por quantidade (top 10)
        top_count = (
            df_mes.groupby("item_name")["order_details_id"]
            .count()
            .reset_index()
            .rename(columns={"item_name": "nome", "order_details_id": "pedidos"})
            .sort_values("pedidos", ascending=False)
            .head(10)
        )
        top_pedidos = [
            {"nome": row["nome"], "pedidos": int(row["pedidos"])}
            for _, row in top_count.iterrows()
        ]

        dados_lista.append(
            {
                "mes": month_name,
                "faturamento": faturamento,
                "vendas": pedidos,
                "clientes": itens_total,
                "ticket": faturamento / pedidos,
            }
        )

        dados_por_mes[month_name] = {
            "faturamento": round(faturamento, 2),
            "vendas": pedidos,
            "clientes": itens_total,
            "changeFaturamento": 0,
            "changeVendas": 0,
            "changeTicket": 0,
            "changeClientes": 0,
            "servicos": servicos,
            "formas_pagamento": formas_pagamento,
            "pedidos_hora": pedidos_hora,
            "top_pedidos": top_pedidos,
        }

        print(f"\n[{month_name.upper()}]")
        print(f"  Faturamento: $ {faturamento:.2f}")
        print(f"  Pedidos: {pedidos}")
        print(f"  Itens vendidos: {itens_total}")
        print(f"  Ticket médio: $ {faturamento / pedidos:.2f}")
        top_3 = ", ".join([s["nome"] for s in servicos[:3]])
        print(f"  Top 3 pratos: {top_3}")

    # Calcular variações mês a mês
    for i in range(1, len(dados_lista)):
        atual = dados_lista[i]
        anterior = dados_lista[i - 1]
        mes = atual["mes"]

        dados_por_mes[mes]["changeFaturamento"] = round(
            (atual["faturamento"] - anterior["faturamento"]) / anterior["faturamento"] * 100, 1
        )
        dados_por_mes[mes]["changeVendas"] = round(
            (atual["vendas"] - anterior["vendas"]) / anterior["vendas"] * 100, 1
        )
        dados_por_mes[mes]["changeClientes"] = round(
            (atual["clientes"] - anterior["clientes"]) / anterior["clientes"] * 100, 1
        )
        dados_por_mes[mes]["changeTicket"] = round(
            (atual["ticket"] - anterior["ticket"]) / anterior["ticket"] * 100, 1
        )

    with open(DADOS_JSON, "w", encoding="utf-8") as f:
        json.dump(dados_por_mes, f, indent=2, ensure_ascii=False)

    print(f"\n[OK] dados.json salvo em: {DADOS_JSON}")


if __name__ == "__main__":
    processar()
