-- ============================================================
-- 03_AGREGACOES.sql
-- Funções de agregação + GROUP BY + HAVING
-- ============================================================
-- Funções de agregação "resumem" muitas linhas em uma só.
-- São essenciais para BI e análise de dados.
--
-- Principais funções:
--   COUNT(*)       → conta linhas
--   COUNT(coluna)  → conta valores não-nulos
--   SUM(coluna)    → soma total
--   AVG(coluna)    → média
--   MIN(coluna)    → menor valor
--   MAX(coluna)    → maior valor
--
-- GROUP BY → agrupa linhas com mesmo valor para aplicar agregação
-- HAVING   → filtra DEPOIS da agregação (WHERE filtra ANTES)
-- ============================================================


-- @query: COUNT — contar registros
-- @desc: Conta o total de clientes cadastrados.
-- @desc: COUNT(*) conta TODAS as linhas, incluindo NULLs.
SELECT COUNT(*) AS total_clientes FROM clientes;


-- @query: COUNT com filtro
-- @desc: Quantos clientes estão ativos?
-- @desc: Combinar COUNT com WHERE é muito comum em relatórios.
SELECT 
    COUNT(*) AS total,
    SUM(CASE WHEN ativo = 1 THEN 1 ELSE 0 END) AS ativos,
    SUM(CASE WHEN ativo = 0 THEN 1 ELSE 0 END) AS inativos
FROM clientes;


-- @query: SUM — soma total
-- @desc: Faturamento total de todos os agendamentos concluídos.
SELECT 
    SUM(valor_cobrado) AS faturamento_bruto,
    SUM(desconto) AS total_descontos,
    SUM(valor_cobrado - desconto) AS faturamento_liquido
FROM agendamentos 
WHERE status = 'concluido';


-- @query: AVG, MIN, MAX — média, mínimo, máximo
-- @desc: Estatísticas do valor cobrado por atendimento.
SELECT 
    ROUND(AVG(valor_cobrado), 2) AS ticket_medio,
    MIN(valor_cobrado) AS menor_valor,
    MAX(valor_cobrado) AS maior_valor,
    COUNT(*) AS total_atendimentos
FROM agendamentos 
WHERE status = 'concluido';


-- @query: GROUP BY — agrupar por uma coluna
-- @desc: Quantos atendimentos cada funcionário fez?
-- @desc: GROUP BY agrupa todas as linhas com o mesmo funcionario_id.
-- @desc: Depois, COUNT conta quantas linhas tem em cada grupo.
SELECT 
    funcionario_id,
    COUNT(*) AS total_atendimentos,
    SUM(valor_cobrado) AS receita_gerada
FROM agendamentos 
WHERE status = 'concluido'
GROUP BY funcionario_id
ORDER BY receita_gerada DESC;


-- @query: GROUP BY com nome (usando subquery simples)
-- @desc: Faturamento por forma de pagamento.
-- @desc: Um dos relatórios mais pedidos em qualquer negócio.
SELECT 
    forma_pagamento,
    COUNT(*) AS quantidade,
    SUM(valor_cobrado) AS total,
    ROUND(AVG(valor_cobrado), 2) AS ticket_medio,
    ROUND(SUM(valor_cobrado) * 100.0 / (SELECT SUM(valor_cobrado) FROM agendamentos WHERE status = 'concluido'), 1) AS percentual
FROM agendamentos 
WHERE status = 'concluido'
GROUP BY forma_pagamento
ORDER BY total DESC;


-- @query: GROUP BY por mês — faturamento mensal
-- @desc: strftime('%m', data) extrai o mês de uma data no SQLite.
-- @desc: %Y = ano, %m = mês, %d = dia.
-- @desc: Este é o relatório base de qualquer dashboard de BI!
SELECT 
    strftime('%Y-%m', data_hora) AS mes,
    COUNT(*) AS atendimentos,
    SUM(valor_cobrado) AS faturamento,
    ROUND(AVG(valor_cobrado), 2) AS ticket_medio
FROM agendamentos 
WHERE status = 'concluido'
GROUP BY strftime('%Y-%m', data_hora)
ORDER BY mes;


-- @query: GROUP BY por categoria de serviço
-- @desc: Qual categoria (cabelo, unha, estética) gera mais receita?
SELECT 
    s.categoria,
    COUNT(*) AS atendimentos,
    SUM(a.valor_cobrado) AS receita,
    ROUND(AVG(a.valor_cobrado), 2) AS ticket_medio
FROM agendamentos a
JOIN servicos s ON a.servico_id = s.id
WHERE a.status = 'concluido'
GROUP BY s.categoria
ORDER BY receita DESC;


-- @query: GROUP BY por dia da semana
-- @desc: Qual dia da semana é mais movimentado?
-- @desc: strftime('%w', data) retorna 0=domingo, 1=segunda, ..., 6=sábado
SELECT 
    CASE strftime('%w', data_hora)
        WHEN '0' THEN 'Domingo'
        WHEN '1' THEN 'Segunda'
        WHEN '2' THEN 'Terça'
        WHEN '3' THEN 'Quarta'
        WHEN '4' THEN 'Quinta'
        WHEN '5' THEN 'Sexta'
        WHEN '6' THEN 'Sábado'
    END AS dia_semana,
    strftime('%w', data_hora) AS dia_num,
    COUNT(*) AS atendimentos,
    SUM(valor_cobrado) AS receita
FROM agendamentos 
WHERE status = 'concluido'
GROUP BY strftime('%w', data_hora)
ORDER BY dia_num;


-- @query: GROUP BY por faixa de horário
-- @desc: Em que horário o salão é mais movimentado?
-- @desc: CAST converte texto para número (para BETWEEN funcionar).
SELECT 
    CASE 
        WHEN CAST(strftime('%H', data_hora) AS INTEGER) BETWEEN 8 AND 10 THEN '08h-10h (Manhã cedo)'
        WHEN CAST(strftime('%H', data_hora) AS INTEGER) BETWEEN 11 AND 13 THEN '11h-13h (Meio-dia)'
        WHEN CAST(strftime('%H', data_hora) AS INTEGER) BETWEEN 14 AND 16 THEN '14h-16h (Tarde)'
        WHEN CAST(strftime('%H', data_hora) AS INTEGER) BETWEEN 17 AND 19 THEN '17h-19h (Final tarde)'
    END AS faixa_horario,
    COUNT(*) AS atendimentos,
    SUM(valor_cobrado) AS receita
FROM agendamentos 
WHERE status = 'concluido'
GROUP BY faixa_horario
ORDER BY atendimentos DESC;


-- @query: HAVING — filtrar DEPOIS da agregação
-- @desc: HAVING é o WHERE do GROUP BY. Filtra os GRUPOS, não as linhas.
-- @desc: Bairros que têm 3 ou mais clientes cadastrados.
SELECT 
    bairro,
    COUNT(*) AS total_clientes
FROM clientes 
GROUP BY bairro
HAVING COUNT(*) >= 3
ORDER BY total_clientes DESC;


-- @query: HAVING com SUM
-- @desc: Meses em que o faturamento ultrapassou R$ 10.000.
SELECT 
    strftime('%Y-%m', data_hora) AS mes,
    SUM(valor_cobrado) AS faturamento
FROM agendamentos 
WHERE status = 'concluido'
GROUP BY strftime('%Y-%m', data_hora)
HAVING SUM(valor_cobrado) > 10000
ORDER BY faturamento DESC;


-- @query: GROUP BY com múltiplas colunas
-- @desc: Faturamento por forma de pagamento POR MÊS.
-- @desc: Cruzamento de duas dimensões — muito usado em BI.
SELECT 
    strftime('%Y-%m', data_hora) AS mes,
    forma_pagamento,
    COUNT(*) AS quantidade,
    SUM(valor_cobrado) AS total
FROM agendamentos 
WHERE status = 'concluido'
GROUP BY strftime('%Y-%m', data_hora), forma_pagamento
ORDER BY mes, total DESC;


-- @query: Taxa de cancelamento por mês
-- @desc: Combina agregação condicional para calcular percentuais.
-- @desc: Este padrão (SUM/CASE/COUNT) é MUITO usado em dashboards.
SELECT 
    strftime('%Y-%m', data_hora) AS mes,
    COUNT(*) AS total_agendamentos,
    SUM(CASE WHEN status = 'concluido' THEN 1 ELSE 0 END) AS concluidos,
    SUM(CASE WHEN status = 'cancelado' THEN 1 ELSE 0 END) AS cancelados,
    SUM(CASE WHEN status = 'no-show' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN status = 'cancelado' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS taxa_cancelamento_pct
FROM agendamentos 
GROUP BY strftime('%Y-%m', data_hora)
ORDER BY mes;


-- @query: Top 5 clientes por gasto
-- @desc: Quem são os clientes VIP (que mais gastam)?
-- @desc: LIMIT 5 após ORDER BY pega apenas os 5 maiores.
SELECT 
    c.nome,
    COUNT(*) AS visitas,
    SUM(a.valor_cobrado) AS gasto_total,
    ROUND(AVG(a.valor_cobrado), 2) AS ticket_medio
FROM agendamentos a
JOIN clientes c ON a.cliente_id = c.id
WHERE a.status = 'concluido'
GROUP BY a.cliente_id
ORDER BY gasto_total DESC
LIMIT 5;


-- @query: Média de nota por funcionário
-- @desc: Qual funcionária tem a melhor avaliação?
-- @desc: ROUND(..., 2) arredonda para 2 casas decimais.
SELECT 
    f.nome AS funcionario,
    f.cargo,
    COUNT(av.id) AS total_avaliacoes,
    ROUND(AVG(av.nota), 2) AS nota_media,
    MIN(av.nota) AS pior_nota,
    MAX(av.nota) AS melhor_nota
FROM avaliacoes av
JOIN agendamentos ag ON av.agendamento_id = ag.id
JOIN funcionarios f ON ag.funcionario_id = f.id
GROUP BY f.id
HAVING COUNT(av.id) >= 5
ORDER BY nota_media DESC;
