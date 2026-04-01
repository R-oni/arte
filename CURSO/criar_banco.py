"""
╔══════════════════════════════════════════════════════════════╗
║         CRIAÇÃO DO BANCO DE DADOS — SALÃO DE BELEZA          ║
║         Aprenda SQL na prática com dados realistas           ║
╚══════════════════════════════════════════════════════════════╝

O QUE ESTE SCRIPT FAZ:
    1. Cria um banco de dados SQLite (arquivo salao.db)
    2. Cria 8 tabelas com relacionamentos entre elas
    3. Insere ~900 registros fictícios mas realistas

CONCEITOS DE BANCO DE DADOS DEMONSTRADOS:
    - Tabelas e colunas (CREATE TABLE)
    - Tipos de dados (TEXT, INTEGER, REAL, DATE, BOOLEAN)
    - Chave primária (PRIMARY KEY)
    - Chave estrangeira (FOREIGN KEY) — relacionamento entre tabelas
    - Restrições (NOT NULL, UNIQUE, DEFAULT, CHECK)
    - Auto-incremento (AUTOINCREMENT)

POR QUE SQLITE?
    - Já vem com o Python (módulo sqlite3)
    - Não precisa instalar servidor (MySQL, PostgreSQL)
    - Tudo fica em um único arquivo .db
    - Sintaxe quase idêntica aos bancos "de verdade"

COMO USAR:
    python criar_banco.py

DEPOIS:
    python executar.py      → roda as consultas SQL e gera relatório
    Abra index.html         → visualize tudo no navegador
"""

import sqlite3
import random
import os
from datetime import datetime, timedelta, date

# ============================================================
# CONFIGURAÇÃO
# ============================================================

# Seed fixa = sempre gera os MESMOS dados
# Isso é importante para reprodutibilidade (todo mundo vê os mesmos resultados)
random.seed(42)

# Caminho do banco — mesmo diretório deste script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(SCRIPT_DIR, 'salao.db')


# ============================================================
# 1. CONEXÃO COM O BANCO
# ============================================================
# sqlite3.connect() cria o arquivo se não existir
# Se já existir, recriamos do zero para garantir dados limpos

def criar_conexao():
    """
    Conecta ao banco SQLite.
    
    PYTHON + SQL:
        conn = sqlite3.connect('arquivo.db')  → abre/cria o banco
        cursor = conn.cursor()                 → cria um "ponteiro" para executar comandos
        cursor.execute("SQL AQUI")             → executa um comando SQL
        conn.commit()                          → salva as alterações
        conn.close()                           → fecha a conexão
    """
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        print("♻  Banco anterior removido.")

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # PRAGMA: comando especial do SQLite
    # foreign_keys = ON → ativa verificação de chaves estrangeiras
    cursor.execute("PRAGMA foreign_keys = ON;")

    print(f"✓  Banco criado em: {DB_PATH}")
    return conn, cursor


# ============================================================
# 2. CRIAÇÃO DAS TABELAS (DDL — Data Definition Language)
# ============================================================
# DDL = comandos que DEFINEM a estrutura do banco
# CREATE TABLE, ALTER TABLE, DROP TABLE

def criar_tabelas(cursor):
    """
    Cria todas as tabelas com tipos, restrições e relacionamentos.
    """

    # ─── TABELA: clientes ─────────────────────────────────────
    # Armazena o cadastro de cada cliente do salão.
    #
    # INTEGER PRIMARY KEY AUTOINCREMENT → ID único, gerado automaticamente
    # TEXT NOT NULL    → texto obrigatório (não pode ser vazio/NULL)
    # TEXT UNIQUE      → texto que não pode se repetir (ex: email)
    # DEFAULT 'valor'  → valor padrão quando não informado
    # BOOLEAN          → no SQLite é INTEGER (0 = falso, 1 = verdadeiro)
    cursor.execute("""
        CREATE TABLE clientes (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            nome            TEXT NOT NULL,
            email           TEXT UNIQUE,
            telefone        TEXT,
            data_nascimento DATE,
            cidade          TEXT DEFAULT 'São Paulo',
            bairro          TEXT,
            data_cadastro   DATE NOT NULL,
            ativo           BOOLEAN DEFAULT 1
        );
    """)
    print("  ✓ Tabela 'clientes' criada")

    # ─── TABELA: funcionarios ─────────────────────────────────
    # Equipe do salão: cabeleireiras, manicures, esteticista, etc.
    #
    # REAL → número decimal (float) — usado para salário e percentuais
    cursor.execute("""
        CREATE TABLE funcionarios (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            nome              TEXT NOT NULL,
            cargo             TEXT NOT NULL,
            salario           REAL NOT NULL,
            comissao_pct      REAL DEFAULT 0,
            data_contratacao  DATE NOT NULL,
            ativo             BOOLEAN DEFAULT 1
        );
    """)
    print("  ✓ Tabela 'funcionarios' criada")

    # ─── TABELA: servicos ─────────────────────────────────────
    # Catálogo de serviços oferecidos pelo salão.
    # Cada serviço tem categoria, preço e duração.
    cursor.execute("""
        CREATE TABLE servicos (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            nome            TEXT NOT NULL,
            categoria       TEXT NOT NULL,
            preco           REAL NOT NULL,
            duracao_minutos INTEGER NOT NULL,
            ativo           BOOLEAN DEFAULT 1
        );
    """)
    print("  ✓ Tabela 'servicos' criada")

    # ─── TABELA: agendamentos ─────────────────────────────────
    # Coração do sistema: cada atendimento realizado.
    # Conecta cliente + funcionário + serviço.
    #
    # FOREIGN KEY → garante que o cliente_id existe na tabela clientes
    #               Se tentar inserir um cliente_id inexistente, dá erro
    # DATETIME    → data + hora (ex: '2025-03-15 14:30:00')
    cursor.execute("""
        CREATE TABLE agendamentos (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente_id        INTEGER NOT NULL,
            funcionario_id    INTEGER NOT NULL,
            servico_id        INTEGER NOT NULL,
            data_hora         DATETIME NOT NULL,
            valor_cobrado     REAL NOT NULL,
            desconto          REAL DEFAULT 0,
            forma_pagamento   TEXT NOT NULL,
            status            TEXT DEFAULT 'concluido',
            observacao        TEXT,
            FOREIGN KEY (cliente_id)     REFERENCES clientes(id),
            FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id),
            FOREIGN KEY (servico_id)     REFERENCES servicos(id)
        );
    """)
    print("  ✓ Tabela 'agendamentos' criada")

    # ─── TABELA: produtos ─────────────────────────────────────
    # Produtos vendidos no salão (shampoos, esmaltes, etc.)
    # Tem preço de custo e preço de venda → permite calcular margem
    cursor.execute("""
        CREATE TABLE produtos (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            nome         TEXT NOT NULL,
            marca        TEXT,
            categoria    TEXT,
            preco_custo  REAL NOT NULL,
            preco_venda  REAL NOT NULL,
            estoque      INTEGER DEFAULT 0
        );
    """)
    print("  ✓ Tabela 'produtos' criada")

    # ─── TABELA: vendas_produtos ──────────────────────────────
    # Registro de vendas de produtos.
    # agendamento_id é OPCIONAL (pode vender sem atendimento).
    #
    # Quando agendamento_id é NULL → venda avulsa (cliente comprou na recepção)
    # Quando tem valor → venda casada com o atendimento
    cursor.execute("""
        CREATE TABLE vendas_produtos (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            agendamento_id  INTEGER,
            produto_id      INTEGER NOT NULL,
            quantidade      INTEGER NOT NULL DEFAULT 1,
            valor_unitario  REAL NOT NULL,
            data_venda      DATE NOT NULL,
            FOREIGN KEY (agendamento_id) REFERENCES agendamentos(id),
            FOREIGN KEY (produto_id)     REFERENCES produtos(id)
        );
    """)
    print("  ✓ Tabela 'vendas_produtos' criada")

    # ─── TABELA: despesas ─────────────────────────────────────
    # Gastos fixos e variáveis do salão.
    # recorrente = 1 → gasto mensal fixo (aluguel, internet)
    # recorrente = 0 → gasto pontual (manutenção, compra extra)
    cursor.execute("""
        CREATE TABLE despesas (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            categoria   TEXT NOT NULL,
            descricao   TEXT,
            valor       REAL NOT NULL,
            data        DATE NOT NULL,
            recorrente  BOOLEAN DEFAULT 0
        );
    """)
    print("  ✓ Tabela 'despesas' criada")

    # ─── TABELA: avaliacoes ───────────────────────────────────
    # Feedback dos clientes após atendimento.
    #
    # CHECK(nota BETWEEN 1 AND 5) → restrição: nota só pode ser 1, 2, 3, 4 ou 5
    # Se tentar inserir nota 6, o banco rejeita.
    cursor.execute("""
        CREATE TABLE avaliacoes (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            agendamento_id  INTEGER NOT NULL,
            nota            INTEGER CHECK(nota BETWEEN 1 AND 5),
            comentario      TEXT,
            data            DATE NOT NULL,
            FOREIGN KEY (agendamento_id) REFERENCES agendamentos(id)
        );
    """)
    print("  ✓ Tabela 'avaliacoes' criada")


# ============================================================
# 3. INSERÇÃO DE DADOS (DML — Data Manipulation Language)
# ============================================================
# DML = comandos que MANIPULAM dados
# INSERT, UPDATE, DELETE, SELECT

def inserir_funcionarios(cursor):
    """
    Insere a equipe do salão.
    
    INSERT INTO tabela (colunas) VALUES (valores);
    
    executemany() → insere vários registros de uma vez (mais eficiente)
    Usa ? como placeholder para evitar SQL Injection
    """
    funcionarios = [
        # (nome, cargo, salario, comissao_pct, data_contratacao, ativo)
        ('Juliana Mendes',   'cabeleireira',  2500.00, 0.35, '2022-03-15', 1),
        ('Carla Nogueira',   'cabeleireira',  2300.00, 0.35, '2022-08-01', 1),
        ('Sandra Vieira',    'cabeleireira',  2200.00, 0.30, '2023-01-10', 1),
        ('Débora Lopes',     'manicure',      1800.00, 0.30, '2022-05-20', 1),
        ('Patrícia Duarte',  'manicure',      1800.00, 0.30, '2023-06-01', 1),
        ('Renata Campos',    'esteticista',   2000.00, 0.30, '2023-03-15', 1),
        ('Lúcia Fernandes',  'recepcionista', 1600.00, 0.00, '2022-01-05', 1),
        ('Marcos Teixeira',  'gerente',       3500.00, 0.00, '2021-11-01', 1),
    ]

    cursor.executemany("""
        INSERT INTO funcionarios (nome, cargo, salario, comissao_pct, data_contratacao, ativo)
        VALUES (?, ?, ?, ?, ?, ?)
    """, funcionarios)
    # O ? é um PLACEHOLDER — o sqlite3 substitui pelos valores da tupla
    # Isso PREVINE SQL Injection (nunca concatene strings em SQL!)

    print(f"  ✓ {len(funcionarios)} funcionários inseridos")


def inserir_servicos(cursor):
    """Insere o catálogo de serviços."""
    servicos = [
        # (nome, categoria, preco, duracao_minutos, ativo)
        # --- CABELO ---
        ('Corte Feminino',    'cabelo',    80.00,  45, 1),
        ('Escova',            'cabelo',    60.00,  40, 1),
        ('Coloração',         'cabelo',   180.00,  90, 1),
        ('Hidratação',        'cabelo',    90.00,  60, 1),
        ('Progressiva',       'cabelo',   250.00, 120, 1),
        ('Luzes / Mechas',    'cabelo',   220.00, 100, 1),
        ('Cauterização',      'cabelo',   120.00,  60, 1),
        ('Botox Capilar',     'cabelo',   150.00,  75, 1),
        # --- UNHAS ---
        ('Manicure',          'unha',      40.00,  30, 1),
        ('Pedicure',          'unha',      45.00,  40, 1),
        ('Unhas em Gel',      'unha',     120.00,  70, 1),
        # --- ESTÉTICA ---
        ('Design Sobrancelha','estetica',  50.00,  20, 1),
        ('Limpeza de Pele',   'estetica', 130.00,  60, 1),
        ('Maquiagem',         'estetica', 100.00,  50, 1),
        ('Depilação',         'estetica',  70.00,  30, 1),
    ]

    cursor.executemany("""
        INSERT INTO servicos (nome, categoria, preco, duracao_minutos, ativo)
        VALUES (?, ?, ?, ?, ?)
    """, servicos)

    print(f"  ✓ {len(servicos)} serviços inseridos")


def inserir_clientes(cursor):
    """
    Gera 60 clientes fictícios com dados realistas.
    Demonstra como gerar dados em massa com Python.
    """
    nomes = [
        'Maria', 'Ana', 'Juliana', 'Camila', 'Letícia', 'Fernanda',
        'Beatriz', 'Larissa', 'Carolina', 'Patrícia', 'Isabela', 'Gabriela',
        'Amanda', 'Daniela', 'Mariana', 'Renata', 'Tatiana', 'Priscila',
        'Vanessa', 'Aline', 'Luciana', 'Bruna', 'Rafaela', 'Cinthia',
        'Roberta', 'Natália', 'Simone', 'Viviane', 'Adriana', 'Thais',
        'Elaine', 'Cristina', 'Denise', 'Flávia', 'Helena', 'Jéssica',
        'Karen', 'Luana', 'Márcia', 'Nathalia', 'Olívia', 'Paula',
        'Raquel', 'Sílvia', 'Teresa', 'Valéria', 'Rita', 'Sueli',
        'Cláudia', 'Déborah', 'Elisa', 'Gisele', 'Heloísa', 'Irene',
        'Joana', 'Kelly', 'Lívia', 'Michele', 'Noemi', 'Sandra'
    ]
    sobrenomes = [
        'Silva', 'Santos', 'Oliveira', 'Ferreira', 'Souza', 'Costa',
        'Pereira', 'Almeida', 'Ribeiro', 'Lima', 'Martins', 'Araújo',
        'Rodrigues', 'Carvalho', 'Gomes', 'Barbosa', 'Nunes', 'Melo',
        'Rocha', 'Dias', 'Castro', 'Nascimento', 'Monteiro', 'Moreira',
        'Pinto', 'Teixeira', 'Duarte', 'Correia', 'Cardoso', 'Vieira'
    ]
    bairros = [
        'Moema', 'Vila Mariana', 'Pinheiros', 'Santana', 'Tatuapé',
        'Lapa', 'Ipiranga', 'Consolação', 'Liberdade', 'Itaim Bibi',
        'Brooklin', 'Campo Belo', 'Perdizes', 'Vila Madalena', 'Butantã'
    ]

    clientes_data = []
    emails_usados = set()

    for i in range(60):
        nome = nomes[i]
        sobrenome = random.choice(sobrenomes)
        nome_completo = f"{nome} {sobrenome}"

        # Gerar email único
        email_base = f"{nome.lower()}.{sobrenome.lower()}@email.com"
        email = email_base.replace('á', 'a').replace('é', 'e').replace('í', 'i') \
                         .replace('ó', 'o').replace('ú', 'u').replace('ã', 'a') \
                         .replace('â', 'a').replace('ê', 'e').replace('ô', 'o') \
                         .replace('ç', 'c').replace('ü', 'u')
        # Se email já existe, adiciona número
        if email in emails_usados:
            email = email.replace('@', f'{i}@')
        emails_usados.add(email)

        telefone = f"(11) 9{random.randint(1000,9999)}-{random.randint(1000,9999)}"

        # Data de nascimento: entre 18 e 65 anos
        ano_nasc = random.randint(1960, 2007)
        mes_nasc = random.randint(1, 12)
        dia_nasc = random.randint(1, 28)
        data_nasc = f"{ano_nasc}-{mes_nasc:02d}-{dia_nasc:02d}"

        bairro = random.choice(bairros)

        # Data de cadastro: entre jan/2023 e jan/2025
        dias_atras = random.randint(0, 730)
        data_cad = (date(2025, 1, 1) - timedelta(days=dias_atras)).isoformat()

        # 90% ativos, 10% inativos (simulando churn)
        ativo = 1 if random.random() < 0.90 else 0

        clientes_data.append((
            nome_completo, email, telefone, data_nasc,
            'São Paulo', bairro, data_cad, ativo
        ))

    cursor.executemany("""
        INSERT INTO clientes (nome, email, telefone, data_nascimento, cidade, bairro, data_cadastro, ativo)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, clientes_data)

    print(f"  ✓ {len(clientes_data)} clientes inseridos")


def inserir_produtos(cursor):
    """Insere catálogo de produtos do salão."""
    produtos = [
        # (nome, marca, categoria, preco_custo, preco_venda, estoque)
        ('Shampoo Reconstrutor',  "L'Oréal",    'shampoo',       25.00,  55.00, 15),
        ('Condicionador Nutritivo',"L'Oréal",   'condicionador', 22.00,  50.00, 12),
        ('Máscara Hidratação',    'Kérastase',  'tratamento',    45.00, 110.00,  8),
        ('Óleo Reparador',        'Moroccanoil', 'tratamento',   55.00, 130.00,  6),
        ('Shampoo Matizador',     "L'Oréal",    'shampoo',       28.00,  65.00, 10),
        ('Leave-in Protetor',     'Redken',     'tratamento',    32.00,  75.00,  9),
        ('Spray Fixador',         "L'Oréal",    'finalização',   18.00,  42.00, 14),
        ('Tintura Profissional',  'Igora',      'coloração',     15.00,  35.00, 25),
        ('Esmalte Clássico',      'Risqué',     'esmalte',        4.00,  12.00, 40),
        ('Esmalte Premium',       'O.P.I.',     'esmalte',       18.00,  42.00, 20),
        ('Removedor de Esmalte',  'Risqué',     'esmalte',        3.00,  10.00, 30),
        ('Base Fortalecedora',    'Risqué',     'esmalte',        8.00,  22.00, 18),
        ('Creme para Mãos',      'Natura',      'cuidados',      12.00,  32.00, 15),
        ('Kit Tratamento Capilar','Kérastase',  'tratamento',    65.00, 160.00,  4),
        ('Sérum Facial',          'Vichy',      'estetica',      35.00,  85.00,  7),
        ('Protetor Solar Facial', 'La Roche',   'estetica',      28.00,  68.00, 11),
        ('Cera Modeladora',       'Redken',     'finalização',   15.00,  38.00, 13),
        ('Ampola Reconstrução',   "L'Oréal",    'tratamento',     8.00,  25.00, 22),
        ('Touca Térmica',         'Genérica',   'acessório',     20.00,  48.00,  5),
        ('Escova Térmica',        'Belliz',     'acessório',     25.00,  58.00,  7),
    ]

    cursor.executemany("""
        INSERT INTO produtos (nome, marca, categoria, preco_custo, preco_venda, estoque)
        VALUES (?, ?, ?, ?, ?, ?)
    """, produtos)

    print(f"  ✓ {len(produtos)} produtos inseridos")


def inserir_agendamentos(cursor):
    """
    Gera ~600 agendamentos (atendimentos) ao longo de 6 meses.
    
    Lógica:
    - Período: Janeiro a Junho de 2025
    - ~100 agendamentos por mês (5-6 por dia útil)
    - Cada agendamento associa: cliente + funcionária + serviço
    - Funcionária é escolhida conforme especialidade (cabeleireira→cabelo, etc.)
    - Status: 88% concluído, 8% cancelado, 4% no-show
    """

    # Mapear funcionários por categoria de serviço
    # cargo → IDs dos funcionários que podem fazer
    cargo_servico = {
        'cabelo':   [1, 2, 3],       # Juliana, Carla, Sandra (cabeleireiras)
        'unha':     [4, 5],           # Débora, Patrícia (manicures)
        'estetica': [6],              # Renata (esteticista)
    }

    # Buscar serviços do banco para ter IDs corretos
    cursor.execute("SELECT id, categoria, preco FROM servicos")
    servicos = cursor.fetchall()  # Lista de tuplas: [(1, 'cabelo', 80.0), ...]

    formas_pagamento = ['PIX', 'Cartão Crédito', 'Cartão Débito', 'Dinheiro']
    pesos_pagamento = [35, 30, 20, 15]  # PIX mais comum

    status_opcoes = ['concluido', 'cancelado', 'no-show']
    pesos_status = [88, 8, 4]

    observacoes_possiveis = [
        None, None, None, None, None,  # maioria sem observação
        'Cliente pediu corte mais curto que o normal',
        'Alergia a amônia — usamos produto sem',
        'Primeira vez no salão — veio por indicação',
        'Remarcou do dia anterior',
        'Cliente fidelidade — desconto aplicado',
        'Trouxe referência de foto do Instagram',
        'Pediu retoque na franja após 15 dias',
        'Cliente VIP — atendimento preferencial',
    ]

    agendamentos_data = []
    # Gerar para cada mês
    for mes in range(1, 7):  # Janeiro a Junho 2025
        # Quantos atendimentos neste mês (variação realista)
        qtd_mes = random.randint(90, 115)

        for _ in range(qtd_mes):
            # Data aleatória no mês (só dias úteis: seg-sab)
            dia = random.randint(1, 28)
            data_base = date(2025, mes, dia)
            # Pular domingos (weekday 6)
            while data_base.weekday() == 6:
                dia = random.randint(1, 28)
                data_base = date(2025, mes, dia)

            # Horário: 8h às 19h
            hora = random.randint(8, 18)
            minuto = random.choice([0, 15, 30, 45])
            data_hora = f"{data_base.isoformat()} {hora:02d}:{minuto:02d}:00"

            # Serviço aleatório
            servico = random.choice(servicos)
            servico_id, categoria, preco_base = servico

            # Funcionária compatível com o serviço
            funcionarios_aptos = cargo_servico.get(categoria, [1, 2, 3])
            funcionario_id = random.choice(funcionarios_aptos)

            # Cliente aleatório (1 a 60)
            cliente_id = random.randint(1, 60)

            # Preço com pequena variação (±8%) — desconto ou taxa extra
            variacao = random.uniform(-0.08, 0.08)
            valor_cobrado = round(preco_base * (1 + variacao), 2)

            # Desconto ocasional (20% de chance)
            desconto = round(random.choice([0, 0, 0, 0, valor_cobrado * 0.1]), 2)

            # Forma de pagamento
            forma = random.choices(formas_pagamento, weights=pesos_pagamento, k=1)[0]

            # Status
            status = random.choices(status_opcoes, weights=pesos_status, k=1)[0]

            # Observação
            obs = random.choice(observacoes_possiveis)

            agendamentos_data.append((
                cliente_id, funcionario_id, servico_id,
                data_hora, valor_cobrado, desconto,
                forma, status, obs
            ))

    cursor.executemany("""
        INSERT INTO agendamentos 
            (cliente_id, funcionario_id, servico_id, data_hora, 
             valor_cobrado, desconto, forma_pagamento, status, observacao)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, agendamentos_data)

    print(f"  ✓ {len(agendamentos_data)} agendamentos inseridos")
    return len(agendamentos_data)


def inserir_vendas_produtos(cursor, total_agendamentos):
    """
    Gera ~200 vendas de produtos.
    ~60% vinculadas a agendamentos, ~40% avulsas.
    """
    vendas_data = []

    for _ in range(210):
        produto_id = random.randint(1, 20)

        # Buscar preço de venda
        cursor.execute("SELECT preco_venda FROM produtos WHERE id = ?", (produto_id,))
        preco = cursor.fetchone()[0]

        quantidade = random.choices([1, 2, 3], weights=[70, 25, 5], k=1)[0]

        # 60% vinculadas a agendamento
        if random.random() < 0.6:
            agendamento_id = random.randint(1, total_agendamentos)
            # Buscar data do agendamento
            cursor.execute("SELECT date(data_hora) FROM agendamentos WHERE id = ?", (agendamento_id,))
            row = cursor.fetchone()
            data_venda = row[0] if row else '2025-03-15'
        else:
            agendamento_id = None  # Venda avulsa → NULL
            mes = random.randint(1, 6)
            dia = random.randint(1, 28)
            data_venda = f"2025-{mes:02d}-{dia:02d}"

        vendas_data.append((agendamento_id, produto_id, quantidade, preco, data_venda))

    cursor.executemany("""
        INSERT INTO vendas_produtos (agendamento_id, produto_id, quantidade, valor_unitario, data_venda)
        VALUES (?, ?, ?, ?, ?)
    """, vendas_data)

    print(f"  ✓ {len(vendas_data)} vendas de produtos inseridas")


def inserir_despesas(cursor):
    """
    Gera despesas mensais do salão (jan-jun 2025).
    Mix de despesas fixas (recorrentes) e variáveis.
    """
    despesas_data = []

    for mes in range(1, 7):
        data_base = f"2025-{mes:02d}"

        # Despesas FIXAS (recorrentes todo mês)
        despesas_data.append(('Aluguel', 'Aluguel do imóvel comercial', 3200.00, f"{data_base}-05", 1))
        despesas_data.append(('Internet', 'Internet fibra + telefone fixo', 200.00, f"{data_base}-10", 1))
        despesas_data.append(('Contador', 'Honorários contábeis mensais', 400.00, f"{data_base}-15", 1))

        # Despesas VARIÁVEIS (mudam a cada mês)
        despesas_data.append(('Energia', f'Conta de luz - {mes:02d}/2025',
                              round(random.uniform(420, 680), 2), f"{data_base}-20", 0))
        despesas_data.append(('Água', f'Conta de água - {mes:02d}/2025',
                              round(random.uniform(170, 290), 2), f"{data_base}-20", 0))
        despesas_data.append(('Produtos', f'Reposição de estoque - {mes:02d}/2025',
                              round(random.uniform(1400, 2600), 2), f"{data_base}-12", 0))
        despesas_data.append(('Marketing', f'Anúncios Instagram/Google - {mes:02d}/2025',
                              round(random.uniform(280, 550), 2), f"{data_base}-08", 0))
        despesas_data.append(('Limpeza', f'Material de limpeza - {mes:02d}/2025',
                              round(random.uniform(140, 270), 2), f"{data_base}-01", 0))

        # Manutenção esporádica (40% de chance por mês)
        if random.random() < 0.4:
            despesas_data.append(('Manutenção', f'Reparo/manutenção - {mes:02d}/2025',
                                  round(random.uniform(200, 900), 2), f"{data_base}-18", 0))

    cursor.executemany("""
        INSERT INTO despesas (categoria, descricao, valor, data, recorrente)
        VALUES (?, ?, ?, ?, ?)
    """, despesas_data)

    print(f"  ✓ {len(despesas_data)} despesas inseridas")


def inserir_avaliacoes(cursor, total_agendamentos):
    """
    Gera ~160 avaliações de clientes.
    Distribuição de notas realista: maioria 4-5, poucas negativas.
    """
    # Apenas agendamentos concluídos podem ter avaliação
    cursor.execute("SELECT id, date(data_hora) FROM agendamentos WHERE status = 'concluido'")
    concluidos = cursor.fetchall()

    # ~30% dos concluídos deixam avaliação
    avaliados = random.sample(concluidos, min(160, int(len(concluidos) * 0.3)))

    comentarios_por_nota = {
        5: [
            'Adorei! Voltarei com certeza.',
            'Profissional incrível, super atenciosa.',
            'Melhor salão da região!',
            'Saí me sentindo outra pessoa.',
            'Atendimento impecável como sempre.',
            'Amei o resultado, ficou perfeito!',
            None, None,  # Algumas sem comentário
        ],
        4: [
            'Muito bom, só demorou um pouco.',
            'Gostei bastante do resultado.',
            'Bom atendimento, ambiente agradável.',
            'Recomendo, mas o preço poderia ser melhor.',
            None, None,
        ],
        3: [
            'Foi ok, nada de especial.',
            'Resultado razoável.',
            'Esperava um pouco mais.',
            None,
        ],
        2: [
            'Não gostei muito do resultado.',
            'Demorou demais para ser atendida.',
        ],
        1: [
            'Péssima experiência, não volto.',
            'Resultado muito diferente do que pedi.',
        ]
    }

    avaliacoes_data = []
    for agendamento_id, data_agendamento in avaliados:
        # Distribuição de notas (ponderada: maioria positiva)
        nota = random.choices([5, 4, 3, 2, 1], weights=[40, 35, 15, 7, 3], k=1)[0]
        comentario = random.choice(comentarios_por_nota[nota])
        avaliacoes_data.append((agendamento_id, nota, comentario, data_agendamento))

    cursor.executemany("""
        INSERT INTO avaliacoes (agendamento_id, nota, comentario, data)
        VALUES (?, ?, ?, ?)
    """, avaliacoes_data)

    print(f"  ✓ {len(avaliacoes_data)} avaliações inseridas")


# ============================================================
# 4. EXECUÇÃO PRINCIPAL
# ============================================================

def main():
    print("\n" + "=" * 55)
    print("  CRIANDO BANCO DE DADOS — SALÃO DE BELEZA")
    print("=" * 55 + "\n")

    conn, cursor = criar_conexao()

    print("\n📋 Criando tabelas...")
    criar_tabelas(cursor)

    print("\n📥 Inserindo dados...")
    inserir_funcionarios(cursor)
    inserir_servicos(cursor)
    inserir_clientes(cursor)
    inserir_produtos(cursor)
    total_ag = inserir_agendamentos(cursor)
    inserir_vendas_produtos(cursor, total_ag)
    inserir_despesas(cursor)
    inserir_avaliacoes(cursor, total_ag)

    # conn.commit() → SALVA todas as alterações no arquivo .db
    # Sem isso, nada é gravado permanentemente!
    conn.commit()

    # Resumo final
    print("\n" + "=" * 55)
    print("  ✅ BANCO CRIADO COM SUCESSO!")
    print("=" * 55)

    tabelas = ['clientes', 'funcionarios', 'servicos', 'agendamentos',
               'produtos', 'vendas_produtos', 'despesas', 'avaliacoes']
    total_geral = 0
    for tabela in tabelas:
        cursor.execute(f"SELECT COUNT(*) FROM {tabela}")
        count = cursor.fetchone()[0]
        total_geral += count
        print(f"  {tabela:.<25} {count:>5} registros")

    print(f"\n  TOTAL {'.' * 19} {total_geral:>5} registros")
    print(f"\n  Arquivo: {DB_PATH}")
    print("\n  Próximo passo: python executar.py\n")

    conn.close()


if __name__ == '__main__':
    main()
