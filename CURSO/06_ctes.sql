-- ============================================================
-- 06_CTES.sql
-- CTEs (Common Table Expressions) — WITH ... AS
-- ============================================================
-- CTE é uma "tabela temporária nomeada" definida com WITH.
-- Funciona como uma subquery, mas MUITO mais legível.
--
-- Sintaxe:
--   WITH nome_cte AS (
--       SELECT ...
--   )
--   SELECT ... FROM nome_cte ...
--
-- Vantagens:
--   ✓ Código mais limpo e legível que subqueries aninhadas
--   ✓ Pode ser referenciada várias vezes na mesma query
--   ✓ Permite CTEs recursivas (hierarquias, sequências)
--   ✓ Facilita debugging (teste cada CTE separadamente)
--
-- É o recurso MAIS QUERIDO por analistas de dados.
-- Se dominar CTE, você resolve 90% dos problemas de BI.
-- ============================================================


-- @query: CTE simples — Faturamento por mês
-- @desc: CTE substitui subquery no FROM. Compare com a versão de subquery.
-- @desc: WITH cria a "tabela" faturamento_mensal, que usamos embaixo.
WITH faturamento_mensal AS (
    SELECT 
        strftime('%Y-%m', data_hora) AS mes,
        COUNT(*) AS atendimentos,
        SUM(valor_cobrado) AS receita,
        ROUND(AVG(valor_cobrado), 2) AS ticket_medio
    FROM agendamentos 
    WHERE status = 'concluido'
    GROUP BY strftime('%Y-%m', data_hora)
)
SELECT 
    mes,
    atendimentos,
    receita,
    ticket_medio,
    ROUND(receita * 100.0 / (SELECT SUM(receita) FROM faturamento_mensal), 1) AS pct_total
FROM faturamento_mensal
ORDER BY mes;


-- @query: Múltiplas CTEs — DRE Completo (Demonstrativo de Resultado)
-- @desc: Você pode definir VÁRIAS CTEs separadas por vírgula.
-- @desc: Cada uma se torna uma "tabela" disponível para as próximas.
-- @desc: Este é um mini DRE (relatório financeiro) do salão.
WITH receitas AS (
    SELECT 
        strftime('%Y-%m', data_hora) AS mes,
        SUM(valor_cobrado) AS receita_servicos
    FROM agendamentos 
    WHERE status = 'concluido'
    GROUP BY strftime('%Y-%m', data_hora)
),
receitas_produtos AS (
    SELECT 
        strftime('%Y-%m', data_venda) AS mes,
        SUM(quantidade * valor_unitario) AS receita_produtos
    FROM vendas_produtos
    GROUP BY strftime('%Y-%m', data_venda)
),
custos AS (
    SELECT 
        strftime('%Y-%m', data) AS mes,
        SUM(valor) AS total_despesas
    FROM despesas
    GROUP BY strftime('%Y-%m', data)
),
comissoes AS (
    SELECT 
        strftime('%Y-%m', a.data_hora) AS mes,
        ROUND(SUM(a.valor_cobrado * f.comissao_pct), 2) AS total_comissoes
    FROM agendamentos a
    JOIN funcionarios f ON a.funcionario_id = f.id
    WHERE a.status = 'concluido'
    GROUP BY strftime('%Y-%m', a.data_hora)
)
SELECT 
    r.mes,
    r.receita_servicos,
    COALESCE(rp.receita_produtos, 0) AS receita_produtos,
    (r.receita_servicos + COALESCE(rp.receita_produtos, 0)) AS receita_total,
    COALESCE(c.total_despesas, 0) AS despesas,
    COALESCE(com.total_comissoes, 0) AS comissoes,
    ROUND(r.receita_servicos + COALESCE(rp.receita_produtos, 0) 
          - COALESCE(c.total_despesas, 0) 
          - COALESCE(com.total_comissoes, 0), 2) AS lucro_liquido
FROM receitas r
LEFT JOIN receitas_produtos rp ON r.mes = rp.mes
LEFT JOIN custos c ON r.mes = c.mes
LEFT JOIN comissoes com ON r.mes = com.mes
ORDER BY r.mes;


-- @query: CTE para análise de recorrência (retenção de clientes)
-- @desc: Identifica quantos clientes vieram em 2+ meses diferentes.
-- @desc: Essencial para medir fidelização.
WITH clientes_por_mes AS (
    SELECT 
        cliente_id,
        strftime('%Y-%m', data_hora) AS mes
    FROM agendamentos
    WHERE status = 'concluido'
    GROUP BY cliente_id, strftime('%Y-%m', data_hora)
),
frequencia AS (
    SELECT 
        cliente_id,
        COUNT(DISTINCT mes) AS meses_ativos
    FROM clientes_por_mes
    GROUP BY cliente_id
)
SELECT 
    CASE 
        WHEN meses_ativos = 1 THEN '1 mês (eventual)'
        WHEN meses_ativos = 2 THEN '2 meses'
        WHEN meses_ativos = 3 THEN '3 meses'
        WHEN meses_ativos BETWEEN 4 AND 5 THEN '4-5 meses'
        ELSE '6 meses (super fiel)'
    END AS frequencia,
    COUNT(*) AS clientes,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM frequencia), 1) AS percentual
FROM frequencia
GROUP BY 
    CASE 
        WHEN meses_ativos = 1 THEN '1 mês (eventual)'
        WHEN meses_ativos = 2 THEN '2 meses'
        WHEN meses_ativos = 3 THEN '3 meses'
        WHEN meses_ativos BETWEEN 4 AND 5 THEN '4-5 meses'
        ELSE '6 meses (super fiel)'
    END
ORDER BY MIN(meses_ativos);


-- @query: CTE para análise de churn (perda de clientes)
-- @desc: Clientes que vieram nos primeiros 3 meses mas NÃO voltaram depois.
-- @desc: "Churn" = taxa de abandono. Métrica crucial em qualquer negócio.
WITH primeira_visita AS (
    SELECT 
        cliente_id,
        MIN(data_hora) AS primeira,
        MAX(data_hora) AS ultima
    FROM agendamentos 
    WHERE status = 'concluido'
    GROUP BY cliente_id
),
churn AS (
    SELECT 
        cliente_id,
        date(primeira) AS primeira_visita,
        date(ultima) AS ultima_visita,
        CAST(julianday(ultima) - julianday(primeira) AS INTEGER) AS dias_entre_visitas,
        CASE 
            WHEN ultima < '2025-04-01' THEN 'Provável churn'
            ELSE 'Ativo'
        END AS status_cliente
    FROM primeira_visita
)
SELECT 
    status_cliente,
    COUNT(*) AS clientes,
    ROUND(AVG(dias_entre_visitas), 0) AS media_dias_ativo
FROM churn
GROUP BY status_cliente;


-- @query: CTE com comparação mês a mês (crescimento)
-- @desc: Calcula o crescimento percentual comparado ao mês anterior.
-- @desc: Usa CTE + subquery correlata para pegar o mês anterior.
WITH mensal AS (
    SELECT 
        strftime('%Y-%m', data_hora) AS mes,
        SUM(valor_cobrado) AS receita,
        COUNT(*) AS atendimentos
    FROM agendamentos 
    WHERE status = 'concluido'
    GROUP BY strftime('%Y-%m', data_hora)
),
mensal_numerado AS (
    SELECT 
        mes,
        receita,
        atendimentos,
        ROW_NUMBER() OVER (ORDER BY mes) AS num
    FROM mensal
)
SELECT 
    m1.mes,
    m1.receita,
    m1.atendimentos,
    COALESCE(m0.receita, 0) AS receita_anterior,
    CASE 
        WHEN m0.receita IS NULL THEN '—'
        ELSE ROUND((m1.receita - m0.receita) * 100.0 / m0.receita, 1) || '%'
    END AS crescimento
FROM mensal_numerado m1
LEFT JOIN mensal_numerado m0 ON m1.num = m0.num + 1
ORDER BY m1.mes;


-- @query: CTE para análise ABC de clientes
-- @desc: Classificação ABC: os 20% que mais gastam = A, próximos 30% = B, resto = C.
-- @desc: Padrão clássico de análise de negócios (Regra de Pareto / 80-20).
WITH gastos AS (
    SELECT 
        c.nome,
        SUM(a.valor_cobrado) AS gasto_total
    FROM agendamentos a
    JOIN clientes c ON a.cliente_id = c.id
    WHERE a.status = 'concluido'
    GROUP BY a.cliente_id
),
ranking AS (
    SELECT 
        nome,
        gasto_total,
        SUM(gasto_total) OVER (ORDER BY gasto_total DESC) AS acumulado,
        SUM(gasto_total) OVER () AS total_geral
    FROM gastos
)
SELECT 
    nome,
    gasto_total,
    ROUND(gasto_total * 100.0 / total_geral, 1) AS pct_individual,
    ROUND(acumulado * 100.0 / total_geral, 1) AS pct_acumulado,
    CASE 
        WHEN acumulado * 100.0 / total_geral <= 50 THEN 'A (Top)'
        WHEN acumulado * 100.0 / total_geral <= 80 THEN 'B (Médio)'
        ELSE 'C (Cauda)'
    END AS classe_abc
FROM ranking
ORDER BY gasto_total DESC
LIMIT 20;
