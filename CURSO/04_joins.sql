-- ============================================================
-- 04_JOINS.sql
-- Combinando dados de múltiplas tabelas
-- ============================================================
-- JOIN conecta duas ou mais tabelas usando uma condição.
-- É o recurso que torna bancos relacionais tão poderosos.
--
-- Tipos de JOIN:
--   INNER JOIN → retorna apenas linhas que existem nas DUAS tabelas
--   LEFT JOIN  → retorna tudo da esquerda + matches da direita (ou NULL)
--   RIGHT JOIN → retorna tudo da direita + matches da esquerda (SQLite não suporta)
--   CROSS JOIN → combina todas as linhas (produto cartesiano)
--
-- Dica: sempre use aliases (a, c, f, s) para encurtar os nomes.
-- ============================================================


-- @query: INNER JOIN — combinar agendamentos + clientes
-- @desc: INNER JOIN retorna apenas linhas com correspondência nas DUAS tabelas.
-- @desc: Aqui trazemos o NOME do cliente ao invés de só o ID.
-- @desc: ON define a condição de ligação entre as tabelas.
SELECT 
    a.id AS agendamento,
    c.nome AS cliente,
    a.data_hora,
    a.valor_cobrado,
    a.forma_pagamento
FROM agendamentos a
INNER JOIN clientes c ON a.cliente_id = c.id
WHERE a.status = 'concluido'
ORDER BY a.data_hora DESC
LIMIT 15;


-- @query: JOIN com 3 tabelas — agendamento completo
-- @desc: Cruzamos 3 tabelas para ter a visão completa do atendimento:
-- @desc: quem foi atendido (cliente), quem atendeu (funcionário) e o quê (serviço).
SELECT 
    a.id,
    c.nome AS cliente,
    f.nome AS profissional,
    s.nome AS servico,
    s.categoria,
    a.data_hora,
    a.valor_cobrado,
    a.forma_pagamento
FROM agendamentos a
JOIN clientes c      ON a.cliente_id = c.id
JOIN funcionarios f  ON a.funcionario_id = f.id
JOIN servicos s      ON a.servico_id = s.id
WHERE a.status = 'concluido'
ORDER BY a.data_hora DESC
LIMIT 15;


-- @query: JOIN com 4 tabelas — atendimento + avaliação
-- @desc: Agora incluímos a avaliação do cliente sobre o atendimento.
-- @desc: Nem todo atendimento tem avaliação, então usamos LEFT JOIN.
SELECT 
    c.nome AS cliente,
    f.nome AS profissional,
    s.nome AS servico,
    a.data_hora,
    a.valor_cobrado,
    av.nota,
    av.comentario
FROM agendamentos a
JOIN clientes c      ON a.cliente_id = c.id
JOIN funcionarios f  ON a.funcionario_id = f.id
JOIN servicos s      ON a.servico_id = s.id
LEFT JOIN avaliacoes av ON av.agendamento_id = a.id
WHERE a.status = 'concluido' AND av.nota IS NOT NULL
ORDER BY av.nota DESC, a.data_hora DESC
LIMIT 15;


-- @query: LEFT JOIN — incluir registros sem correspondência
-- @desc: LEFT JOIN mantém TODAS as linhas da tabela da esquerda.
-- @desc: Se não há correspondência na direita, os campos vêm como NULL.
-- @desc: Aqui encontramos clientes que NUNCA agendaram (sem atendimento).
SELECT 
    c.nome,
    c.email,
    c.data_cadastro,
    COUNT(a.id) AS total_agendamentos
FROM clientes c
LEFT JOIN agendamentos a ON c.id = a.cliente_id
GROUP BY c.id
HAVING COUNT(a.id) = 0
ORDER BY c.data_cadastro;


-- @query: LEFT JOIN — produtos nunca vendidos
-- @desc: Produtos em estoque que ninguém comprou.
-- @desc: vp.id IS NULL → não existe nenhuma venda para esse produto.
SELECT 
    p.nome,
    p.marca,
    p.categoria,
    p.preco_venda,
    p.estoque
FROM produtos p
LEFT JOIN vendas_produtos vp ON p.id = vp.produto_id
WHERE vp.id IS NULL;


-- @query: Relatório de comissões por funcionário
-- @desc: Calcula quanto cada funcionário geraria de comissão.
-- @desc: comissao = valor_cobrado × comissao_pct do funcionário.
-- @desc: Essencial para a folha de pagamento!
SELECT 
    f.nome,
    f.cargo,
    f.comissao_pct * 100 || '%' AS taxa,
    COUNT(a.id) AS atendimentos,
    SUM(a.valor_cobrado) AS receita_gerada,
    ROUND(SUM(a.valor_cobrado * f.comissao_pct), 2) AS comissao_total,
    ROUND(f.salario + SUM(a.valor_cobrado * f.comissao_pct), 2) AS remuneracao_total
FROM funcionarios f
LEFT JOIN agendamentos a ON f.id = a.funcionario_id AND a.status = 'concluido'
GROUP BY f.id
ORDER BY comissao_total DESC;


-- @query: Comissão por funcionário POR MÊS
-- @desc: Visão mensal da comissão — útil para controle de folha.
SELECT 
    strftime('%Y-%m', a.data_hora) AS mes,
    f.nome AS profissional,
    COUNT(a.id) AS atendimentos,
    SUM(a.valor_cobrado) AS receita,
    ROUND(SUM(a.valor_cobrado * f.comissao_pct), 2) AS comissao
FROM agendamentos a
JOIN funcionarios f ON a.funcionario_id = f.id
WHERE a.status = 'concluido'
GROUP BY strftime('%Y-%m', a.data_hora), f.id
ORDER BY mes, comissao DESC;


-- @query: Ranking de serviços mais populares
-- @desc: JOIN + GROUP BY + ORDER BY — combo clássico de relatório.
SELECT 
    s.nome AS servico,
    s.categoria,
    s.preco AS preco_tabela,
    COUNT(*) AS vezes_realizado,
    SUM(a.valor_cobrado) AS receita_total,
    ROUND(AVG(a.valor_cobrado), 2) AS valor_medio_cobrado
FROM agendamentos a
JOIN servicos s ON a.servico_id = s.id
WHERE a.status = 'concluido'
GROUP BY s.id
ORDER BY vezes_realizado DESC;


-- @query: Receita vs Despesas por mês (DRE simplificado)
-- @desc: Demonstra como unir dados de tabelas diferentes para criar um relatório financeiro.
-- @desc: Usa subqueries no SELECT para buscar de tabelas diferentes.
SELECT 
    mes,
    receita,
    despesa,
    ROUND(receita - despesa, 2) AS lucro,
    ROUND((receita - despesa) * 100.0 / receita, 1) AS margem_pct
FROM (
    SELECT 
        r.mes,
        r.receita,
        COALESCE(d.despesa, 0) AS despesa
    FROM 
        (SELECT strftime('%Y-%m', data_hora) AS mes, SUM(valor_cobrado) AS receita
         FROM agendamentos WHERE status = 'concluido' GROUP BY strftime('%Y-%m', data_hora)) r
    LEFT JOIN 
        (SELECT strftime('%Y-%m', data) AS mes, SUM(valor) AS despesa
         FROM despesas GROUP BY strftime('%Y-%m', data)) d
    ON r.mes = d.mes
)
ORDER BY mes;


-- @query: Vendas de produtos com detalhes
-- @desc: JOIN entre vendas, produtos e (opcionalmente) agendamentos.
-- @desc: Vemos quem comprou qual produto e se foi durante um atendimento.
SELECT 
    vp.data_venda,
    p.nome AS produto,
    p.marca,
    vp.quantidade,
    vp.valor_unitario,
    (vp.quantidade * vp.valor_unitario) AS total_venda,
    COALESCE(c.nome, '— Venda avulsa —') AS cliente
FROM vendas_produtos vp
JOIN produtos p ON vp.produto_id = p.id
LEFT JOIN agendamentos a ON vp.agendamento_id = a.id
LEFT JOIN clientes c ON a.cliente_id = c.id
ORDER BY vp.data_venda DESC
LIMIT 15;


-- @query: Cross Join — todas as combinações
-- @desc: CROSS JOIN gera o produto cartesiano (todas combinações possíveis).
-- @desc: Útil para criar "grades" — aqui: todas as funcionárias × todos os serviços.
-- @desc: Na prática usamos para encontrar combinações que AINDA NÃO aconteceram.
SELECT 
    f.nome AS profissional,
    s.nome AS servico
FROM funcionarios f
CROSS JOIN servicos s
WHERE f.cargo = 'cabeleireira' AND s.categoria = 'cabelo'
ORDER BY f.nome, s.nome;


-- @query: Histórico de um cliente específico
-- @desc: Visão completa de todos os atendimentos de uma cliente.
-- @desc: Simula a "ficha do cliente" em um sistema.
SELECT 
    a.data_hora,
    s.nome AS servico,
    f.nome AS profissional,
    a.valor_cobrado,
    a.desconto,
    a.forma_pagamento,
    a.status,
    av.nota,
    av.comentario
FROM agendamentos a
JOIN servicos s ON a.servico_id = s.id
JOIN funcionarios f ON a.funcionario_id = f.id
LEFT JOIN avaliacoes av ON av.agendamento_id = a.id
WHERE a.cliente_id = 1
ORDER BY a.data_hora DESC;
