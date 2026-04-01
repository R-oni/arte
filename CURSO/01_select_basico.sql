-- ============================================================
-- 01_SELECT_BASICO.sql
-- Fundamentos do SELECT: consultar dados de tabelas
-- ============================================================
-- O SELECT é o comando mais usado em SQL.
-- Serve para CONSULTAR (ler) dados de uma ou mais tabelas.
-- Ele NÃO modifica nada no banco — é apenas leitura.
--
-- Sintaxe básica:
--   SELECT colunas FROM tabela;
-- ============================================================


-- @query: Selecionar TODAS as colunas de uma tabela
-- @desc: SELECT * retorna todas as colunas. O asterisco (*) significa "tudo".
-- @desc: Use com LIMIT para não trazer milhares de linhas de uma vez.
-- @desc: Em produção, evite SELECT * — liste só as colunas que precisa.
SELECT * FROM clientes LIMIT 10;


-- @query: Selecionar colunas específicas
-- @desc: Liste as colunas separadas por vírgula.
-- @desc: Isso é mais eficiente que SELECT * porque o banco lê menos dados.
SELECT nome, email, cidade, bairro FROM clientes LIMIT 10;


-- @query: Alias (apelido) com AS
-- @desc: AS renomeia uma coluna no resultado. Útil para deixar mais legível.
-- @desc: O alias NÃO muda o nome real da coluna no banco.
SELECT 
    nome AS "Nome Completo",
    email AS "E-mail",
    bairro AS "Bairro"
FROM clientes 
LIMIT 10;


-- @query: DISTINCT — valores únicos (sem repetição)
-- @desc: DISTINCT remove duplicatas do resultado.
-- @desc: Aqui vemos quais bairros diferentes os clientes moram.
SELECT DISTINCT bairro FROM clientes ORDER BY bairro;


-- @query: Contar valores distintos
-- @desc: COUNT(DISTINCT coluna) conta quantos valores únicos existem.
SELECT 
    COUNT(DISTINCT bairro) AS "Qtd Bairros",
    COUNT(DISTINCT cidade) AS "Qtd Cidades"
FROM clientes;


-- @query: ORDER BY — ordenar resultados
-- @desc: ORDER BY ordena o resultado. Padrão é ASC (crescente).
-- @desc: Use DESC para ordem decrescente (maior → menor).
SELECT nome, data_cadastro 
FROM clientes 
ORDER BY data_cadastro DESC 
LIMIT 10;


-- @query: Ordenar por múltiplas colunas
-- @desc: Primeiro ordena por cidade, e dentro de cada cidade ordena por nome.
SELECT nome, cidade, bairro 
FROM clientes 
ORDER BY cidade ASC, nome ASC 
LIMIT 15;


-- @query: LIMIT e OFFSET — paginação
-- @desc: LIMIT N retorna apenas N linhas.
-- @desc: OFFSET N pula as primeiras N linhas (útil para paginação).
-- @desc: Aqui pegamos os clientes da "página 2" (linhas 11-20).
SELECT nome, email 
FROM clientes 
ORDER BY nome 
LIMIT 10 OFFSET 10;


-- @query: Cálculos em colunas
-- @desc: Você pode fazer contas diretamente no SELECT.
-- @desc: Aqui calculamos a margem de lucro de cada produto.
SELECT 
    nome,
    preco_custo,
    preco_venda,
    (preco_venda - preco_custo) AS lucro_unitario,
    ROUND((preco_venda - preco_custo) * 100.0 / preco_custo, 1) AS margem_pct
FROM produtos
ORDER BY margem_pct DESC;


-- @query: Concatenar textos com ||
-- @desc: O operador || junta textos (concatenação).
-- @desc: Criamos um "resumo" combinando nome e cargo.
SELECT 
    nome || ' (' || cargo || ')' AS funcionario,
    'R$ ' || PRINTF('%.2f', salario) AS salario_formatado,
    comissao_pct * 100 || '%' AS comissao
FROM funcionarios;


-- @query: Serviços com preço por minuto
-- @desc: Demonstra divisão e arredondamento com ROUND.
-- @desc: Qual serviço tem o melhor "custo-benefício" por minuto?
SELECT 
    nome,
    preco,
    duracao_minutos,
    ROUND(preco / duracao_minutos, 2) AS preco_por_minuto
FROM servicos
ORDER BY preco_por_minuto DESC;
