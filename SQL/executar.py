"""
╔══════════════════════════════════════════════════════════════╗
║       EXECUTAR CONSULTAS SQL E GERAR RELATÓRIO HTML          ║
║       Este script é a ponte: SQL → Python → HTML             ║
╚══════════════════════════════════════════════════════════════╝

O QUE FAZ:
    1. Lê todos os arquivos .sql da pasta
    2. Parseia as queries (título, descrição, SQL)
    3. Executa cada query no banco salao.db
    4. Salva resultados em resultados.json
    5. O index.html carrega esse JSON e exibe tudo bonito

CONCEITOS PYTHON + SQL DEMONSTRADOS:
    - sqlite3: conexão, cursor, fetchall, description
    - Parsing de arquivos .sql com regex
    - Serialização JSON
    - Tratamento de erros
    - Pathlib para caminhos de arquivo

COMO USAR:
    python executar.py
"""

import sqlite3
import json
import os
import re
from pathlib import Path

# ============================================================
# CONFIGURAÇÃO
# ============================================================

SCRIPT_DIR = Path(__file__).parent
DB_PATH = SCRIPT_DIR / 'salao.db'
OUTPUT_PATH = SCRIPT_DIR / 'resultados.json'

# Arquivos SQL na ordem que devem ser executados
SQL_FILES = [
    '01_select_basico.sql',
    '02_filtros.sql',
    '03_agregacoes.sql',
    '04_joins.sql',
    '05_subqueries.sql',
    '06_ctes.sql',
    '07_window_functions.sql',
    '08_case_strings_datas.sql',
    '09_insert_update_delete.sql',
]

# Títulos das seções (mapeados por arquivo)
SECTION_TITLES = {
    '01_select_basico.sql':         '1. SELECT Básico — Consultando dados',
    '02_filtros.sql':               '2. WHERE — Filtrando resultados',
    '03_agregacoes.sql':            '3. Agregações — COUNT, SUM, AVG, GROUP BY',
    '04_joins.sql':                 '4. JOINs — Combinando tabelas',
    '05_subqueries.sql':            '5. Subqueries — Consultas dentro de consultas',
    '06_ctes.sql':                  '6. CTEs — Common Table Expressions (WITH)',
    '07_window_functions.sql':      '7. Window Functions — Funções de janela',
    '08_case_strings_datas.sql':    '8. CASE, Strings e Datas',
    '09_insert_update_delete.sql':  '9. INSERT, UPDATE, DELETE, Views e Índices',
}


# ============================================================
# PARSER DE ARQUIVOS .SQL
# ============================================================

def parse_sql_file(filepath):
    """
    Lê um arquivo .sql e extrai as queries com seus metadados.
    
    Formato esperado nos arquivos .sql:
        -- @query: Título da Query
        -- @desc: Descrição do que faz
        -- @desc: Pode ter múltiplas linhas
        SELECT ...;
    
    Retorna lista de dicts:
        [{ "titulo": "...", "descricao": "...", "sql": "..." }, ...]
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    queries = []
    
    # Dividir por "-- @query:" que marca o início de cada query
    # O primeiro split será o cabeçalho do arquivo (ignoramos)
    blocks = re.split(r'-- @query:\s*', content)
    
    for block in blocks[1:]:  # Pular o primeiro (cabeçalho)
        lines = block.strip().split('\n')
        
        titulo = lines[0].strip()
        descricao_lines = []
        sql_lines = []
        in_sql = False
        
        for line in lines[1:]:
            stripped = line.strip()
            
            if stripped.startswith('-- @desc:'):
                # Linha de descrição
                desc_text = stripped.replace('-- @desc:', '').strip()
                descricao_lines.append(desc_text)
            elif stripped.startswith('-- ') and not in_sql:
                # Comentário comum antes do SQL — inclui na descrição
                # (mas só se ainda não começou o SQL)
                pass
            else:
                # Qualquer outra coisa é SQL
                in_sql = True
                sql_lines.append(line.rstrip())
        
        sql = '\n'.join(sql_lines).strip()
        
        # Remover linhas vazias no início/fim do SQL
        sql = sql.strip()
        
        if sql:
            queries.append({
                'titulo': titulo,
                'descricao': ' '.join(descricao_lines),
                'sql': sql,
            })
    
    return queries


# ============================================================
# EXECUTOR DE QUERIES
# ============================================================

def executar_query(cursor, sql):
    """
    Executa uma query SQL e retorna os resultados.
    
    Para queries que modificam dados (INSERT, UPDATE, DELETE),
    retorna apenas uma mensagem de confirmação.
    
    Retorna:
        (colunas, linhas) ou (["resultado"], [["mensagem"]])
    """
    # Separar múltiplos statements (ex: CREATE INDEX seguido de SELECT)
    # Executamos todos, mas retornamos resultado apenas do último SELECT
    statements = [s.strip() for s in sql.split(';') if s.strip()]
    
    colunas = []
    linhas = []
    
    for stmt in statements:
        try:
            cursor.execute(stmt)
            
            # Se o statement retorna dados (SELECT)
            if cursor.description:
                colunas = [desc[0] for desc in cursor.description]
                linhas = cursor.fetchall()
            else:
                # DML statements (INSERT, UPDATE, DELETE, CREATE)
                rows_affected = cursor.rowcount
                if rows_affected >= 0:
                    colunas = ['resultado']
                    linhas = [[f'✓ {rows_affected} linha(s) afetada(s)']]
                    
        except Exception as e:
            colunas = ['erro']
            linhas = [[str(e)]]
    
    return colunas, linhas


# ============================================================
# MAIN
# ============================================================

def main():
    print("\n" + "=" * 55)
    print("  EXECUTANDO CONSULTAS SQL")
    print("=" * 55)
    
    # Verificar se o banco existe
    if not DB_PATH.exists():
        print(f"\n  ❌ Banco não encontrado: {DB_PATH}")
        print("  Execute primeiro: python criar_banco.py\n")
        return
    
    # Conectar ao banco
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    cursor.execute("PRAGMA foreign_keys = ON;")
    
    resultados = {
        'titulo': 'SQL na Prática — Salão de Beleza',
        'subtitulo': 'Aprenda SQL com dados reais de um salão de beleza',
        'banco': 'salao.db (SQLite)',
        'secoes': []
    }
    
    total_queries = 0
    total_erros = 0
    
    for sql_file in SQL_FILES:
        filepath = SCRIPT_DIR / sql_file
        
        if not filepath.exists():
            print(f"  ⚠  Arquivo não encontrado: {sql_file}")
            continue
        
        print(f"\n  📄 {sql_file}")
        
        queries = parse_sql_file(filepath)
        secao = {
            'titulo': SECTION_TITLES.get(sql_file, sql_file),
            'arquivo': sql_file,
            'consultas': []
        }
        
        for q in queries:
            try:
                colunas, linhas = executar_query(cursor, q['sql'])
                
                # Converter para listas serializáveis (sqlite3 retorna tuplas)
                linhas_lista = [list(row) for row in linhas]
                
                # Limitar a 50 linhas no JSON (para não ficar gigante)
                truncado = len(linhas_lista) > 50
                if truncado:
                    linhas_lista = linhas_lista[:50]
                
                secao['consultas'].append({
                    'titulo': q['titulo'],
                    'descricao': q['descricao'],
                    'sql': q['sql'],
                    'colunas': colunas,
                    'linhas': linhas_lista,
                    'total_linhas': len(linhas),
                    'truncado': truncado,
                    'erro': None
                })
                
                total_queries += 1
                status = f"✓ {len(linhas)} linhas"
                print(f"    {status:.<40} {q['titulo']}")
                
            except Exception as e:
                secao['consultas'].append({
                    'titulo': q['titulo'],
                    'descricao': q['descricao'],
                    'sql': q['sql'],
                    'colunas': [],
                    'linhas': [],
                    'total_linhas': 0,
                    'truncado': False,
                    'erro': str(e)
                })
                total_erros += 1
                print(f"    ✗ ERRO: {e}")
        
        resultados['secoes'].append(secao)
    
    # Fazer commit para salvar alterações do arquivo 09 (INSERT/UPDATE/DELETE)
    conn.commit()
    conn.close()
    
    # Salvar JSON
    with open(str(OUTPUT_PATH), 'w', encoding='utf-8') as f:
        json.dump(resultados, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 55)
    print(f"  ✅ {total_queries} queries executadas com sucesso")
    if total_erros:
        print(f"  ⚠  {total_erros} erros encontrados")
    print(f"  📊 Resultados salvos em: {OUTPUT_PATH}")
    print(f"\n  Próximo passo: abra index.html no navegador!")
    print("=" * 55 + "\n")


if __name__ == '__main__':
    main()
