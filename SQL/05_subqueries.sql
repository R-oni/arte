-- ============================================================
-- 05_SUBQUERIES.sql
-- Subqueries (subconsultas): consultas dentro de consultas
-- ============================================================
-- Uma subquery é um SELECT dentro de outro SELECT.
-- Permite resolver problemas complexos "quebrando" em etapas.
--
-- Tipos de subquery:
--   1. Escalar   → retorna UM valor (uma linha, uma coluna)
--   2. Coluna    → retorna uma lista de valores (várias linhas, uma coluna)
--   3. Tabela    → retorna uma tabela inteira (usada no FROM)
--   4. Correlata → referencia a consulta externa (roda para cada linha)
--
-- Operadores comuns com subqueries:
--   IN, NOT IN, EXISTS, NOT EXISTS, ANY, ALL
-- ============================================================


-- @query: Subquery escalar — comparar com uma média
-- @desc: Serviços com preço ACIMA da média geral.
-- @desc: A subquery (SELECT AVG...) retorna um único número.
SELECT 
    nome, 
    categoria, 
    preco,
    (SELECT ROUND(AVG(preco), 2) FROM servicos) AS media_geral
FROM servicos 
WHERE preco > (SELECT AVG(preco) FROM servicos)
ORDER BY preco DESC;


-- @query: Subquery com IN — clientes que vieram em março
-- @desc: IN (subquery) verifica se o valor está na lista retornada.
-- @desc: Primeiro a subquery encontra os IDs, depois o SELECT externo filtra.
SELECT nome, email, bairro
FROM clientes 
WHERE id IN (
    SELECT DISTINCT cliente_id 
    FROM agendamentos 
    WHERE data_hora BETWEEN '2025-03-01' AND '2025-03-31 23:59:59'
    AND status = 'concluido'
)
ORDER BY nome;


-- @query: NOT IN — clientes que NUNCA vieram
-- @desc: NOT IN retorna quem NÃO está na lista.
-- @desc: Clientes cadastrados que nunca fizeram um agendamento.
SELECT nome, email, data_cadastro
FROM clientes 
WHERE id NOT IN (
    SELECT DISTINCT cliente_id FROM agendamentos
)
ORDER BY data_cadastro;


-- @query: EXISTS — verificar existência
-- @desc: EXISTS retorna TRUE se a subquery retornar PELO MENOS uma linha.
-- @desc: É mais eficiente que IN quando a lista interna é grande.
-- @desc: Funcionários que atenderam em junho.
SELECT nome, cargo
FROM funcionarios f
WHERE EXISTS (
    SELECT 1 
    FROM agendamentos a 
    WHERE a.funcionario_id = f.id 
    AND a.data_hora BETWEEN '2025-06-01' AND '2025-06-30 23:59:59'
    AND a.status = 'concluido'
);


-- @query: NOT EXISTS — sem correspondência
-- @desc: Funcionários que NÃO fizeram nenhum atendimento em janeiro.
SELECT nome, cargo
FROM funcionarios f
WHERE NOT EXISTS (
    SELECT 1 
    FROM agendamentos a 
    WHERE a.funcionario_id = f.id 
    AND a.data_hora BETWEEN '2025-01-01' AND '2025-01-31 23:59:59'
);


-- @query: Subquery no FROM — criar tabela temporária
-- @desc: A subquery no FROM cria uma "tabela virtual" que você pode consultar.
-- @desc: Aqui criamos uma visão do gasto total por cliente, depois filtramos.
SELECT 
    nome,
    total_gasto,
    total_visitas,
    ROUND(total_gasto / total_visitas, 2) AS ticket_medio
FROM (
    SELECT 
        c.nome,
        SUM(a.valor_cobrado) AS total_gasto,
        COUNT(*) AS total_visitas
    FROM agendamentos a
    JOIN clientes c ON a.cliente_id = c.id
    WHERE a.status = 'concluido'
    GROUP BY a.cliente_id
) sub
WHERE total_visitas >= 5
ORDER BY total_gasto DESC
LIMIT 10;


-- @query: Subquery correlata — comparar com o grupo
-- @desc: Subquery CORRELATA referencia a consulta externa (usa alias da tabela de fora).
-- @desc: Roda uma vez para cada linha da consulta principal.
-- @desc: Agendamentos onde o valor cobrado foi ACIMA da média do mesmo serviço.
SELECT 
    a.id,
    s.nome AS servico,
    a.valor_cobrado,
    (SELECT ROUND(AVG(a2.valor_cobrado), 2) 
     FROM agendamentos a2 
     WHERE a2.servico_id = a.servico_id AND a2.status = 'concluido'
    ) AS media_servico
FROM agendamentos a
JOIN servicos s ON a.servico_id = s.id
WHERE a.status = 'concluido'
AND a.valor_cobrado > (
    SELECT AVG(a2.valor_cobrado) 
    FROM agendamentos a2 
    WHERE a2.servico_id = a.servico_id AND a2.status = 'concluido'
)
ORDER BY a.valor_cobrado DESC
LIMIT 15;


-- @query: Subquery para classificar clientes
-- @desc: Classifica clientes por faixa de gasto usando subquery + CASE.
-- @desc: Primeiro calcula o gasto total, depois categoriza.
SELECT 
    faixa,
    COUNT(*) AS clientes,
    ROUND(AVG(total_gasto), 2) AS gasto_medio
FROM (
    SELECT 
        c.nome,
        SUM(a.valor_cobrado) AS total_gasto,
        CASE 
            WHEN SUM(a.valor_cobrado) >= 2000 THEN 'VIP (R$ 2000+)'
            WHEN SUM(a.valor_cobrado) >= 1000 THEN 'Frequente (R$ 1000-2000)'
            WHEN SUM(a.valor_cobrado) >= 500  THEN 'Regular (R$ 500-1000)'
            ELSE 'Eventual (< R$ 500)'
        END AS faixa
    FROM agendamentos a
    JOIN clientes c ON a.cliente_id = c.id
    WHERE a.status = 'concluido'
    GROUP BY a.cliente_id
) sub
GROUP BY faixa
ORDER BY gasto_medio DESC;


-- @query: Mês com maior faturamento
-- @desc: Subquery escalar para encontrar o "campeão".
-- @desc: A subquery interna encontra o MAX, a externa busca os detalhes.
SELECT 
    strftime('%Y-%m', data_hora) AS mes,
    COUNT(*) AS atendimentos,
    SUM(valor_cobrado) AS faturamento
FROM agendamentos 
WHERE status = 'concluido'
GROUP BY strftime('%Y-%m', data_hora)
HAVING SUM(valor_cobrado) = (
    SELECT MAX(fat) FROM (
        SELECT SUM(valor_cobrado) AS fat 
        FROM agendamentos 
        WHERE status = 'concluido'
        GROUP BY strftime('%Y-%m', data_hora)
    )
);


-- @query: Serviço mais popular de cada categoria
-- @desc: Usa subquery correlata para encontrar o mais realizado por categoria.
-- @desc: Para cada serviço, verifica se é o que tem mais agendamentos na sua categoria.
SELECT 
    s.categoria,
    s.nome AS servico_mais_popular,
    COUNT(a.id) AS vezes_realizado
FROM servicos s
JOIN agendamentos a ON s.id = a.servico_id
WHERE a.status = 'concluido'
GROUP BY s.id
HAVING COUNT(a.id) = (
    SELECT MAX(cnt) FROM (
        SELECT COUNT(a2.id) AS cnt
        FROM servicos s2
        JOIN agendamentos a2 ON s2.id = a2.servico_id
        WHERE s2.categoria = s.categoria AND a2.status = 'concluido'
        GROUP BY s2.id
    )
)
ORDER BY vezes_realizado DESC;
