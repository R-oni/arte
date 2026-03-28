#!/usr/bin/env python3
"""
Processador de dados para Cliente #1 (Salão Beauty Pro)

Lê CSVs da pasta atual e gera dados.json para o dashboard
Executar: python clientes/1/processar.py
"""

import pandas as pd
import json
from collections import defaultdict
from pathlib import Path

# Diretórios (relativos ao script)
SCRIPT_DIR = Path(__file__).parent
DADOS_JSON = SCRIPT_DIR / "dados.json"

def processar_cliente():
    """Processa todos os CSVs do cliente"""
    
    # Encontrar CSVs na pasta atual (excluir despesas)
    csv_files = [f for f in SCRIPT_DIR.glob("*.csv") if not f.name.startswith("despesas")]
    despesas_files = list(SCRIPT_DIR.glob("despesas*.csv"))
    
    if not csv_files:
        print(f"[ERRO] Nenhum arquivo CSV encontrado em {SCRIPT_DIR}")
        return
    
    print(f"[INFO] Encontrados {len(csv_files)} arquivo(s) CSV de vendas")
    if despesas_files:
        print(f"[INFO] Encontrados {len(despesas_files)} arquivo(s) CSV de despesas")
    
    # Mapeamento de meses
    mes_map = {
        'Janeiro': 'janeiro',
        'Fevereiro': 'fevereiro',
        'Marco': 'março',
        'Março': 'março',
        'Abril': 'abril',
        'Maio': 'maio',
        'Junho': 'junho',
        'Julho': 'julho',
        'Agosto': 'agosto',
        'Setembro': 'setembro',
        'Outubro': 'outubro',
        'Novembro': 'novembro',
        'Dezembro': 'dezembro',
    }
    
    DIAS_SEMANA = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo']
    DIAS_PT_MAP = {
        'segunda-feira': 0,
        'terca-feira': 1, 'terça-feira': 1,
        'quarta-feira': 2,
        'quinta-feira': 3,
        'sexta-feira': 4,
        'sabado': 5, 'sábado': 5,
        'domingo': 6
    }
    
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
        'servicos': defaultdict(float),
        'atividade_semana': defaultdict(float)
    })
    
    # Preparar mapeamento numérico para meses (para arquivos com coluna 'data')
    num_mes_map = {
        1: 'Janeiro', 2: 'Fevereiro', 3: 'Março', 4: 'Abril', 5: 'Maio', 6: 'Junho',
        7: 'Julho', 8: 'Agosto', 9: 'Setembro', 10: 'Outubro', 11: 'Novembro', 12: 'Dezembro'
    }

    # Processar linhas (suporta tanto CSVs com coluna 'mes' quanto com 'data')
    for idx, row in df_consolidado.iterrows():
        # Determinar mês: preferir coluna 'mes', senão tentar extrair de 'data' (DD/MM/YYYY)
        mes_raw = None
        if 'mes' in df_consolidado.columns and pd.notna(row.get('mes')):
            mes_raw = row.get('mes')
        elif 'data' in df_consolidado.columns and pd.notna(row.get('data')):
            try:
                dt = pd.to_datetime(row.get('data'), dayfirst=True, errors='coerce')
                if not pd.isna(dt):
                    mes_raw = num_mes_map.get(int(dt.month))
            except Exception:
                mes_raw = None

        # Valores e campos flexíveis (aceita 'pagamento' ou 'forma_pagamento')
        valor = row.get('valor', 0)
        servico = row.get('servico', 'Desconhecido')
        cliente = row.get('cliente') if 'cliente' in df_consolidado.columns and pd.notna(row.get('cliente')) else 'Sem nome'
        pagamento = None
        if 'pagamento' in df_consolidado.columns and pd.notna(row.get('pagamento')):
            pagamento = row.get('pagamento')
        elif 'forma_pagamento' in df_consolidado.columns and pd.notna(row.get('forma_pagamento')):
            pagamento = row.get('forma_pagamento')
        
        # Se não foi possível determinar mês, pular linha
        if not mes_raw:
            continue

        # Converter chave do mês para formato usado (ex: 'Maio' -> 'maio')
        mes_chave = mes_map.get(mes_raw, str(mes_raw).lower())

        # Adicionar venda
        dados_por_mes[mes_chave]['vendas'].append({
            'servico': str(servico).strip(),
            'valor': float(valor),
            'pagamento': str(pagamento).strip() if pagamento is not None else 'Desconhecido'
        })
        dados_por_mes[mes_chave]['total'] += float(valor)
        dados_por_mes[mes_chave]['quantidade'] += 1
        dados_por_mes[mes_chave]['clientes_unicos'].add(str(cliente).strip())
        
        # Agrupar forma de pagamento
        if pagamento is not None and pd.notna(pagamento):
            dados_por_mes[mes_chave]['formas_pagamento'][str(pagamento).strip()] += float(valor)
        
        # Agrupar serviços
        dados_por_mes[mes_chave]['servicos'][str(servico).strip()] += float(valor)
        
        # Agrupar por dia da semana
        data_val = row.get('data') if 'data' in df_consolidado.columns else None
        if data_val is not None and pd.notna(data_val):
            data_str = str(data_val).strip()
            dia_idx = None
            if ',' in data_str:
                # Formato PT: "sexta-feira, 2 de janeiro de 2026"
                nome_dia = data_str.split(',')[0].strip().lower()
                dia_idx = DIAS_PT_MAP.get(nome_dia)
                if dia_idx is None:
                    nome_ascii = nome_dia.encode('ascii', 'ignore').decode()
                    dia_idx = DIAS_PT_MAP.get(nome_ascii)
            else:
                # Formato ISO: "2026-03-01"
                try:
                    dt = pd.to_datetime(data_str, dayfirst=True, errors='coerce')
                    if not pd.isna(dt):
                        dia_idx = int(dt.weekday())  # 0=Segunda ... 6=Domingo
                except Exception:
                    pass
            if dia_idx is not None:
                dados_por_mes[mes_chave]['atividade_semana'][dia_idx] += float(valor)
    
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
            ],
            'atividade_semana': [
                {'nome': DIAS_SEMANA[i], 'faturamento': round(dados_mes['atividade_semana'].get(i, 0), 2)}
                for i in range(7)
                if dados_mes['atividade_semana'].get(i, 0) > 0
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
    
    # Preservar insights manuais do JSON anterior (se existir)
    if DADOS_JSON.exists():
        try:
            with open(DADOS_JSON, 'r', encoding='utf-8') as f:
                dados_anteriores = json.load(f)
            for mes, dados_mes in dados_dashboard.items():
                if mes in dados_anteriores and 'insights' in dados_anteriores[mes]:
                    dados_mes['insights'] = dados_anteriores[mes]['insights']
        except Exception:
            pass

    # Processar despesas
    if despesas_files:
        df_despesas = pd.DataFrame()
        for csv_path in despesas_files:
            print(f"[LENDO DESPESAS] {csv_path.name}")
            df = pd.read_csv(csv_path)
            df_despesas = pd.concat([df_despesas, df], ignore_index=True)

        for idx, row in df_despesas.iterrows():
            mes_raw = row.get('mes')
            if not mes_raw:
                continue
            mes_chave = mes_map.get(mes_raw, str(mes_raw).lower())
            if mes_chave not in dados_dashboard:
                continue
            categoria = str(row.get('categoria', 'Outros')).strip()
            valor = float(row.get('valor', 0))
            if 'despesas_agg' not in dados_dashboard[mes_chave]:
                dados_dashboard[mes_chave]['despesas_agg'] = defaultdict(float)
            dados_dashboard[mes_chave]['despesas_agg'][categoria] += valor

        for mes_chave, dados_mes in dados_dashboard.items():
            agg = dados_mes.pop('despesas_agg', None)
            if agg:
                despesas_sorted = sorted(agg.items(), key=lambda x: x[1], reverse=True)
                dados_mes['despesas'] = [
                    {'categoria': cat, 'valor': round(val, 2)} for cat, val in despesas_sorted
                ]
                dados_mes['total_despesas'] = round(sum(agg.values()), 2)
                print(f"  [{mes_chave.upper()}] Despesas: R$ {dados_mes['total_despesas']:.2f}")

    # Calcular changeLucro
    ordem_meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
                   'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro']
    meses_com_dados = [m for m in ordem_meses if m in dados_dashboard]
    for i, mes_chave in enumerate(meses_com_dados):
        dm = dados_dashboard[mes_chave]
        lucro_atual = dm['faturamento'] - dm.get('total_despesas', 0)
        if i == 0:
            dm['changeLucro'] = 0
        else:
            dm_ant = dados_dashboard[meses_com_dados[i-1]]
            lucro_ant = dm_ant['faturamento'] - dm_ant.get('total_despesas', 0)
            dm['changeLucro'] = round(((lucro_atual - lucro_ant) / lucro_ant * 100) if lucro_ant > 0 else 0, 1)

    # Salvar JSON
    with open(DADOS_JSON, 'w', encoding='utf-8') as f:
        json.dump(dados_dashboard, f, indent=2, ensure_ascii=False)
    
    print(f"\n[OK] JSON salvo em: {DADOS_JSON}")

if __name__ == '__main__':
    processar_cliente()
