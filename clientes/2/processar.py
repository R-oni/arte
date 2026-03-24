#!/usr/bin/env python3
"""
Processador de dados para Cliente #2 (PetCare Plus)

Lê CSVs da pasta atual e gera dados.json para o dashboard
Executar: python clientes/2/processar.py
"""

import pandas as pd
import json
from collections import defaultdict
from pathlib import Path
from datetime import datetime

# Diretórios (relativos ao script)
SCRIPT_DIR = Path(__file__).parent
DADOS_JSON = SCRIPT_DIR / "dados.json"

def extrair_mes(data_str):
    """Extrai mês de uma data no formato DD/MM/YYYY"""
    try:
        data_obj = datetime.strptime(data_str, "%d/%m/%Y")
        meses = ['', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
                 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro']
        return meses[data_obj.month]
    except:
        return None

def processar_cliente():
    """Processa todos os CSVs do cliente"""
    
    # Encontrar CSVs na pasta atual
    csv_files = list(SCRIPT_DIR.glob("*.csv"))
    
    if not csv_files:
        print(f"[ERRO] Nenhum arquivo CSV encontrado em {SCRIPT_DIR}")
        return
    
    print(f"[INFO] Encontrados {len(csv_files)} arquivo(s) CSV")
    
    # Dataframe consolidado
    df_consolidado = pd.DataFrame()
    
    # Ler todos os CSVs
    for csv_path in csv_files:
        print(f"[LENDO] {csv_path.name}")
        df = pd.read_csv(csv_path)
        df_consolidado = pd.concat([df_consolidado, df], ignore_index=True)
    
    print(f"[INFO] Total de {len(df_consolidado)} registros")
    
    # Agrupar por mês
    dados_por_mes = defaultdict(lambda: {
        'vendas': [],
        'total': 0,
        'quantidade': 0,
        'clientes_unicos': set(),
        'formas_pagamento': defaultdict(float),
        'servicos': defaultdict(float)
    })
    
    # Processar linhas
    for idx, row in df_consolidado.iterrows():
        mes_chave = extrair_mes(row['data'])
        if not mes_chave:
            continue
            
        valor = float(row['valor'])
        servico = str(row['servico']).strip()
        cliente = str(row['cliente']).strip() if pd.notna(row['cliente']) else 'Sem nome'
        pagamento = str(row['forma_pagamento']).strip() if pd.notna(row['forma_pagamento']) else 'Desconhecido'
        
        # Adicionar venda
        dados_por_mes[mes_chave]['vendas'].append({
            'servico': servico,
            'valor': valor,
            'pagamento': pagamento
        })
        dados_por_mes[mes_chave]['total'] += valor
        dados_por_mes[mes_chave]['quantidade'] += 1
        dados_por_mes[mes_chave]['clientes_unicos'].add(cliente)
        
        # Agrupar forma de pagamento
        dados_por_mes[mes_chave]['formas_pagamento'][pagamento] += valor
        
        # Agrupar serviços
        dados_por_mes[mes_chave]['servicos'][servico] += valor
    
    # Formatar para dashboard
    dados_dashboard = {}
    dados_lista = []  # Para cálculo de variações
    
    # Ordenar por mês
    ordem_meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 
                   'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro']
    meses_ordenados = [m for m in ordem_meses if m in dados_por_mes]
    
    for mes_chave in meses_ordenados:
        dados = dados_por_mes[mes_chave]
        
        if dados['quantidade'] == 0:
            continue
        
        # KPIs
        faturamento = dados['total']
        vendas = dados['quantidade']
        ticket_medio = faturamento / vendas if vendas > 0 else 0
        clientes = len(dados['clientes_unicos'])
        
        dados_lista.append({
            'mes': mes_chave,
            'faturamento': faturamento,
            'vendas': vendas,
            'clientes': clientes,
            'ticket': ticket_medio
        })
    
    # Calcular variações
    for i, dados in enumerate(dados_lista):
        if i == 0:
            change_faturamento = 0
            change_vendas = 0
            change_ticket = 0
            change_clientes = 0
        else:
            dados_anterior = dados_lista[i-1]
            change_faturamento = ((dados['faturamento'] - dados_anterior['faturamento']) / dados_anterior['faturamento'] * 100) if dados_anterior['faturamento'] > 0 else 0
            change_vendas = ((dados['vendas'] - dados_anterior['vendas']) / dados_anterior['vendas'] * 100) if dados_anterior['vendas'] > 0 else 0
            change_ticket = ((dados['ticket'] - dados_anterior['ticket']) / dados_anterior['ticket'] * 100) if dados_anterior['ticket'] > 0 else 0
            change_clientes = ((dados['clientes'] - dados_anterior['clientes']) / dados_anterior['clientes'] * 100) if dados_anterior['clientes'] > 0 else 0
        
        mes_chave = dados['mes']
        dados_mes = dados_por_mes[mes_chave]
        
        # Todos os serviços (ordenados por faturamento)
        top_servicos = sorted(dados_mes['servicos'].items(), key=lambda x: x[1], reverse=True)
        
        # Forma de pagamento
        formas_pg = dados_mes['formas_pagamento']
        
        dados_dashboard[mes_chave] = {
            'faturamento': round(dados['faturamento'], 2),
            'vendas': dados['vendas'],
            'clientes': dados['clientes'],
            'changeVendas': round(change_vendas, 1),
            'changeFaturamento': round(change_faturamento, 1),
            'changeTicket': round(change_ticket, 1),
            'changeClientes': round(change_clientes, 1),
            'servicos': [
                {'nome': nome, 'faturamento': round(valor, 2)} 
                for nome, valor in top_servicos
            ],
            'formas_pagamento': [
                {'nome': nome, 'valor': round(valor, 2)} 
                for nome, valor in sorted(formas_pg.items(), key=lambda x: x[1], reverse=True)
            ]
        }
        
        print(f"\n[{mes_chave.upper()}]")
        print(f"  Faturamento: R$ {dados['faturamento']:.2f} ({change_faturamento:+.1f}%)")
        print(f"  Vendas: {dados['vendas']} ({change_vendas:+.1f}%)")
        print(f"  Clientes: {dados['clientes']} ({change_clientes:+.1f}%)")
        print(f"  Ticket Médio: R$ {dados['ticket']:.2f} ({change_ticket:+.1f}%)")
        top_3 = ', '.join([s[0] for s in top_servicos[:3]])
        print(f"  Top Serviços: {top_3}") 
        print(f"  Formas de Pagamento: {list(formas_pg.keys())}")
    
    # Salvar JSON
    with open(DADOS_JSON, 'w', encoding='utf-8') as f:
        json.dump(dados_dashboard, f, indent=2, ensure_ascii=False)
    
    print(f"\n[OK] JSON salvo em: {DADOS_JSON}")

if __name__ == '__main__':
    processar_cliente()
