-- ============================================================
-- 08_CASE_STRINGS_DATAS.sql
-- CASE WHEN, COALESCE, funções de string e data, UNION
-- ============================================================
-- Este arquivo cobre recursos complementares essenciais:
--
-- CASE WHEN → "IF/ELSE" do SQL (lógica condicional)
-- COALESCE  → substitui NULL por valor padrão
-- Strings   → UPPER, LOWER, LENGTH, SUBSTR, REPLACE, TRIM
-- Datas     → date(), strftime(), julianday(), datetime modifiers
-- UNION     → combina resultados de várias queries
-- CAST      → converte tipos de dados
-- ============================================================


-- ===== CASE WHEN =====

-- @query: CASE WHEN — classificar valores em faixas
-- @desc: CASE WHEN funciona como IF/ELSE. Avalia condições em ordem.
-- @desc: A primeira condição TRUE determina o resultado. ELSE é o "senão".
SELECT 
    nome,
    preco,
    CASE 
        WHEN preco >= 200 THEN 'Premium'
        WHEN preco >= 100 THEN 'Intermediário'
        WHEN preco >= 50  THEN 'Acessível'
        ELSE 'Econômico'
    END AS faixa_preco
FROM servicos
ORDER BY preco DESC;


-- @query: CASE WHEN dentro de agregação
-- @desc: Conta quantos atendimentos em cada faixa de valor.
-- @desc: Este padrão (SUM + CASE) é usado em TODOS os dashboards.
SELECT 
    strftime('%Y-%m', data_hora) AS mes,
    SUM(CASE WHEN valor_cobrado < 80 THEN 1 ELSE 0 END) AS "ate_R$80",
    SUM(CASE WHEN valor_cobrado BETWEEN 80 AND 150 THEN 1 ELSE 0 END) AS "R$80_a_150",
    SUM(CASE WHEN valor_cobrado > 150 THEN 1 ELSE 0 END) AS "acima_R$150",
    COUNT(*) AS total
FROM agendamentos
WHERE status = 'concluido'
GROUP BY strftime('%Y-%m', data_hora)
ORDER BY mes;


-- @query: CASE WHEN para criar labels humanizados
-- @desc: Transforma códigos/siglas em textos legíveis.
SELECT 
    a.id,
    CASE a.status
        WHEN 'concluido' THEN '✅ Concluído'
        WHEN 'cancelado' THEN '❌ Cancelado'
        WHEN 'no-show'   THEN '⚠️ Não compareceu'
        ELSE a.status
    END AS status_formatado,
    CASE 
        WHEN a.desconto > 0 THEN '🏷️ Com desconto'
        ELSE '—'
    END AS tem_desconto,
    a.valor_cobrado,
    a.desconto
FROM agendamentos a
ORDER BY a.id DESC
LIMIT 15;


-- ===== COALESCE E NULLIF =====

-- @query: COALESCE — substituir NULL por valor padrão
-- @desc: COALESCE(a, b, c) retorna o PRIMEIRO valor não-nulo.
-- @desc: Essencial quando dados podem estar incompletos.
SELECT 
    a.id,
    COALESCE(a.observacao, 'Sem observação') AS observacao,
    COALESCE(av.comentario, 'Sem avaliação') AS feedback
FROM agendamentos a
LEFT JOIN avaliacoes av ON av.agendamento_id = a.id
ORDER BY a.id DESC
LIMIT 15;


-- @query: COALESCE em cálculos — evitar NULL em contas
-- @desc: NULL em operações matemáticas retorna NULL.
-- @desc: COALESCE garante que usamos 0 quando o valor não existe.
SELECT 
    p.nome,
    p.estoque,
    p.preco_venda,
    COALESCE(SUM(vp.quantidade), 0) AS total_vendido,
    p.estoque - COALESCE(SUM(vp.quantidade), 0) AS estoque_real
FROM produtos p
LEFT JOIN vendas_produtos vp ON p.id = vp.produto_id
GROUP BY p.id
ORDER BY total_vendido DESC;


-- ===== FUNÇÕES DE STRING =====

-- @query: UPPER e LOWER — maiúsculas e minúsculas
-- @desc: UPPER converte para MAIÚSCULAS. LOWER para minúsculas.
SELECT 
    nome,
    UPPER(nome) AS nome_maiusculo,
    LOWER(email) AS email_minusculo
FROM clientes 
LIMIT 10;


-- @query: LENGTH, SUBSTR, REPLACE — manipular texto
-- @desc: LENGTH = comprimento. SUBSTR = pedaço do texto. REPLACE = trocar texto.
SELECT 
    nome,
    LENGTH(nome) AS tamanho_nome,
    SUBSTR(nome, 1, INSTR(nome, ' ') - 1) AS primeiro_nome,
    REPLACE(telefone, '(11) ', '') AS tel_sem_ddd
FROM clientes 
LIMIT 10;


-- @query: TRIM — remover espaços
-- @desc: TRIM remove espaços no início e fim. LTRIM só esquerda. RTRIM só direita.
-- @desc: INSTR encontra a posição de um caractere dentro do texto.
SELECT 
    nome,
    TRIM(nome) AS nome_limpo,
    INSTR(email, '@') AS posicao_arroba,
    SUBSTR(email, INSTR(email, '@') + 1) AS dominio_email
FROM clientes 
LIMIT 10;


-- @query: Agrupar por domínio de email
-- @desc: Extraindo e agrupando pela parte depois do @.
SELECT 
    SUBSTR(email, INSTR(email, '@') + 1) AS dominio,
    COUNT(*) AS clientes
FROM clientes 
GROUP BY SUBSTR(email, INSTR(email, '@') + 1)
ORDER BY clientes DESC;


-- ===== FUNÇÕES DE DATA =====

-- @query: Extrair partes de uma data
-- @desc: strftime() formata datas no SQLite. É a função principal de datas.
-- @desc: %Y=ano, %m=mês, %d=dia, %H=hora, %M=minuto, %w=dia semana
SELECT 
    data_hora,
    strftime('%Y', data_hora) AS ano,
    strftime('%m', data_hora) AS mes,
    strftime('%d', data_hora) AS dia,
    strftime('%H', data_hora) AS hora,
    strftime('%w', data_hora) AS dia_semana_num,
    strftime('%W', data_hora) AS semana_do_ano
FROM agendamentos 
LIMIT 10;


-- @query: Idade dos clientes
-- @desc: julianday() converte data para número (dias desde 4713 a.C.).
-- @desc: Dividir a diferença por 365.25 dá a idade em anos.
SELECT 
    nome,
    data_nascimento,
    CAST((julianday('2025-06-30') - julianday(data_nascimento)) / 365.25 AS INTEGER) AS idade
FROM clientes 
WHERE data_nascimento IS NOT NULL
ORDER BY idade
LIMIT 15;


-- @query: Clientes por faixa etária
-- @desc: Combina cálculo de idade + CASE WHEN + GROUP BY.
SELECT 
    CASE 
        WHEN idade BETWEEN 18 AND 25 THEN '18-25 anos'
        WHEN idade BETWEEN 26 AND 35 THEN '26-35 anos'
        WHEN idade BETWEEN 36 AND 45 THEN '36-45 anos'
        WHEN idade BETWEEN 46 AND 55 THEN '46-55 anos'
        ELSE '56+ anos'
    END AS faixa_etaria,
    COUNT(*) AS clientes
FROM (
    SELECT 
        CAST((julianday('2025-06-30') - julianday(data_nascimento)) / 365.25 AS INTEGER) AS idade
    FROM clientes 
    WHERE data_nascimento IS NOT NULL
) sub
GROUP BY faixa_etaria
ORDER BY MIN(idade);


-- @query: Dias desde o último atendimento por cliente
-- @desc: Identifica clientes que não voltam há muito tempo (risco de churn).
SELECT 
    c.nome,
    MAX(date(a.data_hora)) AS ultima_visita,
    CAST(julianday('2025-06-30') - julianday(MAX(a.data_hora)) AS INTEGER) AS dias_sem_vir,
    CASE 
        WHEN CAST(julianday('2025-06-30') - julianday(MAX(a.data_hora)) AS INTEGER) <= 30 THEN 'Ativo'
        WHEN CAST(julianday('2025-06-30') - julianday(MAX(a.data_hora)) AS INTEGER) <= 60 THEN 'Em risco'
        WHEN CAST(julianday('2025-06-30') - julianday(MAX(a.data_hora)) AS INTEGER) <= 90 THEN 'Frio'
        ELSE 'Perdido'
    END AS status_retencao
FROM clientes c
JOIN agendamentos a ON c.id = a.cliente_id
WHERE a.status = 'concluido'
GROUP BY c.id
ORDER BY dias_sem_vir DESC
LIMIT 15;


-- ===== UNION — combinar resultados =====

-- @query: UNION — juntar duas queries
-- @desc: UNION combina os resultados de dois SELECTs em uma tabela só.
-- @desc: UNION ALL mantém duplicatas. UNION sem ALL remove duplicatas.
-- @desc: Os SELECTs devem ter o MESMO número de colunas.
SELECT 'Receita Serviços' AS tipo, SUM(valor_cobrado) AS valor
FROM agendamentos WHERE status = 'concluido'
UNION ALL
SELECT 'Receita Produtos', SUM(quantidade * valor_unitario)
FROM vendas_produtos
UNION ALL
SELECT 'Despesas (-)', -SUM(valor)
FROM despesas
UNION ALL
SELECT 'Comissões (-)', -ROUND(SUM(a.valor_cobrado * f.comissao_pct), 2)
FROM agendamentos a JOIN funcionarios f ON a.funcionario_id = f.id WHERE a.status = 'concluido';


-- @query: UNION para criar tabela de eventos (timeline)
-- @desc: Combina diferentes tipos de evento em uma linha do tempo unificada.
-- @desc: Útil para criar "feed de atividades" ou logs.
SELECT data, tipo, descricao, valor FROM (
    SELECT date(data_hora) AS data, 'Atendimento' AS tipo, 
           'Serviço concluído' AS descricao, valor_cobrado AS valor
    FROM agendamentos WHERE status = 'concluido'
    UNION ALL
    SELECT data_venda, 'Venda Produto', 'Produto vendido', (quantidade * valor_unitario)
    FROM vendas_produtos
    UNION ALL
    SELECT data, 'Despesa', descricao, -valor
    FROM despesas
) timeline
ORDER BY data DESC
LIMIT 20;


-- ===== CAST — converter tipos =====

-- @query: CAST — converter entre tipos de dados
-- @desc: CAST(valor AS tipo) converte explicitamente entre tipos.
-- @desc: INTEGER, REAL, TEXT são os tipos principais no SQLite.
SELECT 
    nome,
    preco,
    CAST(preco AS INTEGER) AS preco_inteiro,
    CAST(preco AS TEXT) AS preco_texto,
    TYPEOF(preco) AS tipo_original,
    TYPEOF(CAST(preco AS INTEGER)) AS tipo_convertido
FROM servicos
LIMIT 5;
