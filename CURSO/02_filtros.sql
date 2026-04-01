-- ============================================================
-- 02_FILTROS.sql
-- WHERE: filtrar linhas que atendem a condições
-- ============================================================
-- O WHERE define QUAIS linhas serão retornadas.
-- Funciona como um "filtro" — só passa o que atende à condição.
--
-- Sintaxe:
--   SELECT colunas FROM tabela WHERE condição;
--
-- Operadores de comparação:
--   =    igual              <>   diferente (ou !=)
--   >    maior que          >=   maior ou igual
--   <    menor que          <=   menor ou igual
-- ============================================================


-- @query: Filtro simples com = (igual)
-- @desc: Retorna apenas os clientes que moram no bairro 'Moema'.
SELECT nome, bairro, data_cadastro 
FROM clientes 
WHERE bairro = 'Moema';


-- @query: Filtro com <> (diferente)
-- @desc: Todos os funcionários que NÃO são recepcionistas.
SELECT nome, cargo, salario 
FROM funcionarios 
WHERE cargo <> 'recepcionista';


-- @query: Filtro numérico com > (maior que)
-- @desc: Serviços que custam mais de R$ 100.
SELECT nome, categoria, preco 
FROM servicos 
WHERE preco > 100
ORDER BY preco DESC;


-- @query: AND — múltiplas condições (todas devem ser verdadeiras)
-- @desc: Funcionários que são cabeleireiras E ganham mais de R$ 2200.
-- @desc: AND = "e" → ambas as condições precisam ser verdade.
SELECT nome, cargo, salario 
FROM funcionarios 
WHERE cargo = 'cabeleireira' AND salario > 2200;


-- @query: OR — pelo menos uma condição verdadeira
-- @desc: Serviços de cabelo OU de estética.
-- @desc: OR = "ou" → basta uma condição ser verdade.
SELECT nome, categoria, preco 
FROM servicos 
WHERE categoria = 'cabelo' OR categoria = 'estetica'
ORDER BY categoria, preco DESC;


-- @query: NOT — negação
-- @desc: Clientes que NÃO são de Pinheiros nem Vila Mariana.
SELECT nome, bairro 
FROM clientes 
WHERE NOT (bairro = 'Pinheiros' OR bairro = 'Vila Mariana')
ORDER BY bairro
LIMIT 15;


-- @query: BETWEEN — intervalo de valores (inclusivo)
-- @desc: Serviços com preço entre R$ 50 e R$ 150.
-- @desc: BETWEEN inclui os extremos (50 e 150 entram no resultado).
SELECT nome, preco 
FROM servicos 
WHERE preco BETWEEN 50 AND 150
ORDER BY preco;


-- @query: BETWEEN com datas
-- @desc: Agendamentos de março de 2025.
-- @desc: BETWEEN funciona com datas também!
SELECT id, data_hora, valor_cobrado, status 
FROM agendamentos 
WHERE data_hora BETWEEN '2025-03-01' AND '2025-03-31 23:59:59'
ORDER BY data_hora
LIMIT 15;


-- @query: IN — lista de valores permitidos
-- @desc: Clientes que moram em Moema, Itaim Bibi ou Brooklin.
-- @desc: IN é um atalho para vários OR: bairro = 'Moema' OR bairro = 'Itaim Bibi' OR ...
SELECT nome, bairro, telefone 
FROM clientes 
WHERE bairro IN ('Moema', 'Itaim Bibi', 'Brooklin')
ORDER BY bairro, nome;


-- @query: NOT IN — excluir valores
-- @desc: Agendamentos pagos com qualquer forma EXCETO Dinheiro.
SELECT id, forma_pagamento, valor_cobrado 
FROM agendamentos 
WHERE forma_pagamento NOT IN ('Dinheiro')
AND status = 'concluido'
LIMIT 15;


-- @query: LIKE — busca por padrão (texto)
-- @desc: % = qualquer sequência de caracteres.
-- @desc: 'M%' = começa com M. '%silva%' = contém "silva". '%a' = termina com "a".
SELECT nome, email 
FROM clientes 
WHERE nome LIKE 'M%'
ORDER BY nome;


-- @query: LIKE com _ (underscore = um caractere)
-- @desc: _ representa EXATAMENTE um caractere.
-- @desc: Aqui buscamos emails com exatamente 4 letras antes do @.
SELECT nome, email 
FROM clientes 
WHERE email LIKE '____@%'
LIMIT 10;


-- @query: IS NULL — buscar valores vazios
-- @desc: NULL significa "sem valor" / "desconhecido".
-- @desc: Não se usa = NULL, e sim IS NULL.
-- @desc: Vendas de produtos SEM agendamento vinculado (vendas avulsas).
SELECT id, produto_id, quantidade, data_venda 
FROM vendas_produtos 
WHERE agendamento_id IS NULL
LIMIT 15;


-- @query: IS NOT NULL — valores preenchidos
-- @desc: Avaliações que TÊM comentário (não nulo).
SELECT agendamento_id, nota, comentario 
FROM avaliacoes 
WHERE comentario IS NOT NULL
ORDER BY nota DESC
LIMIT 15;


-- @query: Combinando múltiplos filtros
-- @desc: Agendamentos concluídos, pagos via PIX, com valor acima de R$ 150.
-- @desc: Demonstra AND com três condições simultâneas.
SELECT 
    id, 
    data_hora, 
    valor_cobrado, 
    forma_pagamento, 
    status
FROM agendamentos 
WHERE status = 'concluido' 
  AND forma_pagamento = 'PIX' 
  AND valor_cobrado > 150
ORDER BY valor_cobrado DESC
LIMIT 15;


-- @query: Clientes inativos cadastrados há mais de 1 ano
-- @desc: Combina filtro booleano (ativo=0) com filtro de data.
-- @desc: date() converte texto em data no SQLite.
SELECT nome, email, data_cadastro, bairro
FROM clientes 
WHERE ativo = 0 
  AND data_cadastro < '2024-06-01'
ORDER BY data_cadastro;


-- @query: Filtro com cálculo
-- @desc: Produtos onde a margem de lucro é maior que 100%.
-- @desc: Você pode usar expressões matemáticas no WHERE.
SELECT 
    nome, 
    marca,
    preco_custo, 
    preco_venda,
    ROUND((preco_venda - preco_custo) * 100.0 / preco_custo, 1) AS margem_pct
FROM produtos 
WHERE (preco_venda - preco_custo) * 100.0 / preco_custo > 100
ORDER BY margem_pct DESC;
