-- ============================================================
-- 09_INSERT_UPDATE_DELETE.sql  
-- Manipulação de dados + Views + Índices
-- ============================================================
-- Até agora usamos apenas SELECT (leitura).
-- Agora aprendemos os comandos que MODIFICAM dados.
--
-- INSERT → adiciona novas linhas
-- UPDATE → modifica linhas existentes
-- DELETE → remove linhas
-- CREATE VIEW  → "tabela virtual" (resultado de uma query salva)
-- CREATE INDEX → acelera buscas (otimização)
--
-- ⚠️ CUIDADO: UPDATE e DELETE sem WHERE afetam TODAS as linhas!
-- Sempre teste com SELECT antes de rodar UPDATE/DELETE.
-- ============================================================


-- ===== INSERT =====

-- @query: INSERT básico — adicionar um registro
-- @desc: INSERT INTO tabela (colunas) VALUES (valores);
-- @desc: Colunas com DEFAULT ou AUTOINCREMENT podem ser omitidas.
INSERT INTO clientes (nome, email, telefone, data_nascimento, cidade, bairro, data_cadastro)
VALUES ('Teste SQL', 'teste@aprendendo.sql', '(11) 99999-0000', '1995-05-15', 'São Paulo', 'Consolação', '2025-06-15');

-- @query: Verificar INSERT — confirmar inserção
-- @desc: Depois de inserir, faça um SELECT para confirmar.
-- @desc: O ID foi gerado automaticamente pelo AUTOINCREMENT.
SELECT id, nome, email, data_cadastro FROM clientes WHERE email = 'teste@aprendendo.sql';


-- @query: INSERT com SELECT — inserir dados de outra tabela
-- @desc: Combina INSERT com SELECT para copiar/transformar dados.
-- @desc: Útil para criar tabelas de resumo ou migrar dados.
-- @desc: (ESTE É SÓ UM EXEMPLO — não executamos para não poluir os dados)
-- INSERT INTO clientes_vip (nome, email, total_gasto)
-- SELECT c.nome, c.email, SUM(a.valor_cobrado)
-- FROM clientes c
-- JOIN agendamentos a ON c.id = a.cliente_id
-- WHERE a.status = 'concluido'
-- GROUP BY c.id
-- HAVING SUM(a.valor_cobrado) > 2000;
SELECT 'Exemplo de INSERT com SELECT (comentado para não alterar dados)' AS nota;


-- ===== UPDATE =====

-- @query: UPDATE — modificar um registro
-- @desc: UPDATE tabela SET coluna = valor WHERE condição;
-- @desc: ⚠️ SEM WHERE, atualiza TODAS as linhas! Sempre use WHERE.
-- @desc: Aqui atualizamos o bairro da cliente de teste.
UPDATE clientes 
SET bairro = 'Vila Madalena', 
    telefone = '(11) 98888-7777'
WHERE email = 'teste@aprendendo.sql';

-- @query: Verificar UPDATE
-- @desc: Confirmar que a alteração foi aplicada corretamente.
SELECT id, nome, bairro, telefone FROM clientes WHERE email = 'teste@aprendendo.sql';


-- @query: UPDATE com cálculo — reajustar preços
-- @desc: Aumentar em 10% todos os serviços de cabelo.
-- @desc: SET pode usar expressões matemáticas.
UPDATE servicos 
SET preco = ROUND(preco * 1.10, 2)
WHERE categoria = 'cabelo';

-- @query: Verificar reajuste de preços
-- @desc: Os serviços de cabelo agora devem estar 10% mais caros.
SELECT nome, categoria, preco FROM servicos ORDER BY categoria, preco DESC;


-- @query: Reverter reajuste (voltar ao preço original)
-- @desc: Dividir por 1.10 para desfazer o aumento de 10%.
UPDATE servicos 
SET preco = ROUND(preco / 1.10, 2)
WHERE categoria = 'cabelo';

-- @query: Confirmar reversão de preços
-- @desc: Preços de cabelo devem ter voltado ao original.
SELECT nome, categoria, preco FROM servicos WHERE categoria = 'cabelo' ORDER BY preco DESC;


-- ===== DELETE =====

-- @query: DELETE — remover registros
-- @desc: DELETE FROM tabela WHERE condição;
-- @desc: ⚠️ SEM WHERE, apaga TUDO! Sempre teste com SELECT antes.
-- @desc: Removemos a cliente de teste que inserimos acima.
DELETE FROM clientes WHERE email = 'teste@aprendendo.sql';

-- @query: Verificar DELETE
-- @desc: A cliente de teste não deve mais existir.
SELECT COUNT(*) AS existe FROM clientes WHERE email = 'teste@aprendendo.sql';


-- ===== VIEWS =====

-- @query: CREATE VIEW — criar uma "tabela virtual"
-- @desc: View é uma query salva com um nome. Parece uma tabela, mas não armazena dados.
-- @desc: Toda vez que você acessa a view, ela re-executa a query.
-- @desc: Ideal para simplificar queries complexas que são usadas frequentemente.
CREATE VIEW IF NOT EXISTS vw_atendimentos_completos AS
SELECT 
    a.id,
    c.nome AS cliente,
    c.bairro,
    f.nome AS profissional,
    f.cargo,
    s.nome AS servico,
    s.categoria,
    a.data_hora,
    a.valor_cobrado,
    a.desconto,
    a.forma_pagamento,
    a.status,
    av.nota,
    av.comentario
FROM agendamentos a
JOIN clientes c ON a.cliente_id = c.id
JOIN funcionarios f ON a.funcionario_id = f.id
JOIN servicos s ON a.servico_id = s.id
LEFT JOIN avaliacoes av ON av.agendamento_id = a.id;

-- @query: Usar a VIEW — muito mais simples!
-- @desc: Agora ao invés de escrever toda aquela query com 4 JOINs...
-- @desc: ...basta fazer SELECT na view como se fosse uma tabela.
SELECT cliente, profissional, servico, data_hora, valor_cobrado, nota
FROM vw_atendimentos_completos
WHERE status = 'concluido' AND nota IS NOT NULL
ORDER BY data_hora DESC
LIMIT 15;


-- @query: VIEW de KPIs mensais
-- @desc: View com os indicadores-chave do dashboard.
-- @desc: Um analista pode simplesmente fazer SELECT * FROM vw_kpis_mensais.
CREATE VIEW IF NOT EXISTS vw_kpis_mensais AS
SELECT 
    strftime('%Y-%m', data_hora) AS mes,
    COUNT(CASE WHEN status = 'concluido' THEN 1 END) AS atendimentos,
    SUM(CASE WHEN status = 'concluido' THEN valor_cobrado ELSE 0 END) AS faturamento,
    ROUND(AVG(CASE WHEN status = 'concluido' THEN valor_cobrado END), 2) AS ticket_medio,
    COUNT(DISTINCT CASE WHEN status = 'concluido' THEN cliente_id END) AS clientes_unicos,
    ROUND(SUM(CASE WHEN status = 'cancelado' THEN 1.0 ELSE 0 END) * 100.0 / COUNT(*), 1) AS taxa_cancelamento
FROM agendamentos
GROUP BY strftime('%Y-%m', data_hora);

-- @query: Consultar VIEW de KPIs
-- @desc: Todos os indicadores do mês em uma única linha por mês.
SELECT * FROM vw_kpis_mensais ORDER BY mes;


-- @query: VIEW de performance das funcionárias
-- @desc: Dashboard de RH com métricas de cada profissional.
CREATE VIEW IF NOT EXISTS vw_performance_funcionarios AS
SELECT 
    f.nome,
    f.cargo,
    COUNT(a.id) AS total_atendimentos,
    SUM(a.valor_cobrado) AS receita_gerada,
    ROUND(AVG(a.valor_cobrado), 2) AS ticket_medio,
    ROUND(SUM(a.valor_cobrado * f.comissao_pct), 2) AS comissao_total,
    ROUND(AVG(av.nota), 2) AS nota_media,
    COUNT(av.id) AS total_avaliacoes
FROM funcionarios f
LEFT JOIN agendamentos a ON f.id = a.funcionario_id AND a.status = 'concluido'
LEFT JOIN avaliacoes av ON av.agendamento_id = a.id
GROUP BY f.id;

-- @query: Consultar performance
-- @desc: Compare as funcionárias lado a lado.
SELECT * FROM vw_performance_funcionarios ORDER BY receita_gerada DESC;


-- ===== INDEX — otimizar buscas =====

-- @query: CREATE INDEX — acelerar consultas
-- @desc: Índice é como o índice de um livro — permite encontrar dados rápido.
-- @desc: Sem índice, o banco precisa ler TODAS as linhas (full scan).
-- @desc: Com índice, ele vai direto ao que precisa.
-- @desc: Crie índices nas colunas usadas em WHERE, JOIN e ORDER BY.
CREATE INDEX IF NOT EXISTS idx_agendamentos_data ON agendamentos(data_hora);
CREATE INDEX IF NOT EXISTS idx_agendamentos_cliente ON agendamentos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_agendamentos_funcionario ON agendamentos(funcionario_id);
CREATE INDEX IF NOT EXISTS idx_agendamentos_status ON agendamentos(status);
CREATE INDEX IF NOT EXISTS idx_vendas_data ON vendas_produtos(data_venda);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_agendamento ON avaliacoes(agendamento_id);
SELECT 'Índices criados com sucesso' AS resultado;


-- @query: Ver índices existentes
-- @desc: sqlite_master armazena metadados do banco (tabelas, views, índices).
-- @desc: Em MySQL seria SHOW INDEX. Em PostgreSQL seria pg_indexes.
SELECT name AS indice, tbl_name AS tabela, sql AS definicao
FROM sqlite_master 
WHERE type = 'index' AND sql IS NOT NULL
ORDER BY tbl_name, name;
