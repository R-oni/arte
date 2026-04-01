-- ============================================================
-- 07_WINDOW_FUNCTIONS.sql
-- Funções de Janela — o recurso mais poderoso do SQL moderno
-- ============================================================
-- Window Functions calculam sobre um "grupo" de linhas sem colapsar.
-- Diferente do GROUP BY, cada linha MANTÉM seus dados originais.
--
-- Sintaxe:
--   funcao() OVER (
--       PARTITION BY coluna     -- define os grupos (opcional)
--       ORDER BY coluna         -- define a ordem (opcional)
--       ROWS BETWEEN ...        -- define a janela (opcional)
--   )
--
-- Funções principais:
--   ROW_NUMBER()  → número sequencial (1, 2, 3...)
--   RANK()        → ranking com empates (1, 1, 3, 4...)
--   DENSE_RANK()  → ranking sem "pulos" (1, 1, 2, 3...)
--   LAG(col, N)   → valor da linha N posições ANTES
--   LEAD(col, N)  → valor da linha N posições DEPOIS
--   SUM() OVER    → soma acumulada
--   AVG() OVER    → média móvel
--   NTILE(N)      → divide em N grupos iguais
--   FIRST_VALUE() → primeiro valor da janela
--   LAST_VALUE()  → último valor da janela
--
-- Window Functions são ESSENCIAIS para BI e análise de dados.
-- Domine isso e você estará acima de 90% dos analistas júnior.
-- ============================================================


-- @query: ROW_NUMBER — numerar linhas sequencialmente
-- @desc: ROW_NUMBER() atribui um número único a cada linha.
-- @desc: Aqui numeramos os serviços do mais caro ao mais barato.
SELECT 
    ROW_NUMBER() OVER (ORDER BY preco DESC) AS posicao,
    nome,
    categoria,
    preco
FROM servicos;


-- @query: RANK vs DENSE_RANK — ranking com empates
-- @desc: RANK pula posições após empate (1,1,3). DENSE_RANK não pula (1,1,2).
-- @desc: Note a diferença quando dois funcionários têm o mesmo número de atendimentos.
SELECT 
    f.nome,
    COUNT(a.id) AS atendimentos,
    RANK() OVER (ORDER BY COUNT(a.id) DESC) AS rank_normal,
    DENSE_RANK() OVER (ORDER BY COUNT(a.id) DESC) AS rank_denso
FROM agendamentos a
JOIN funcionarios f ON a.funcionario_id = f.id
WHERE a.status = 'concluido'
GROUP BY f.id;


-- @query: ROW_NUMBER com PARTITION BY — ranking por grupo
-- @desc: PARTITION BY divide em grupos. ROW_NUMBER reinicia em cada grupo.
-- @desc: Top 3 serviços mais populares de CADA CATEGORIA.
SELECT * FROM (
    SELECT 
        s.categoria,
        s.nome AS servico,
        COUNT(a.id) AS realizacoes,
        ROW_NUMBER() OVER (
            PARTITION BY s.categoria 
            ORDER BY COUNT(a.id) DESC
        ) AS rank_na_categoria
    FROM agendamentos a
    JOIN servicos s ON a.servico_id = s.id
    WHERE a.status = 'concluido'
    GROUP BY s.id
) sub
WHERE rank_na_categoria <= 3;


-- @query: LAG — comparar com a linha anterior
-- @desc: LAG(coluna, N) pega o valor N linhas ANTES (na ordem definida).
-- @desc: Ideal para calcular variação mês a mês.
WITH mensal AS (
    SELECT 
        strftime('%Y-%m', data_hora) AS mes,
        SUM(valor_cobrado) AS receita
    FROM agendamentos 
    WHERE status = 'concluido'
    GROUP BY strftime('%Y-%m', data_hora)
)
SELECT 
    mes,
    receita,
    LAG(receita, 1) OVER (ORDER BY mes) AS receita_mes_anterior,
    receita - LAG(receita, 1) OVER (ORDER BY mes) AS diferenca,
    ROUND(
        (receita - LAG(receita, 1) OVER (ORDER BY mes)) * 100.0 
        / LAG(receita, 1) OVER (ORDER BY mes), 1
    ) AS variacao_pct
FROM mensal;


-- @query: LEAD — olhar para o futuro
-- @desc: LEAD(coluna, N) pega o valor N linhas DEPOIS.
-- @desc: Útil para prever tendências ou calcular tempo entre eventos.
WITH visitas AS (
    SELECT 
        cliente_id,
        date(data_hora) AS data_visita,
        LEAD(date(data_hora), 1) OVER (
            PARTITION BY cliente_id 
            ORDER BY data_hora
        ) AS proxima_visita
    FROM agendamentos
    WHERE status = 'concluido'
)
SELECT 
    c.nome,
    data_visita,
    proxima_visita,
    CAST(julianday(proxima_visita) - julianday(data_visita) AS INTEGER) AS dias_entre_visitas
FROM visitas v
JOIN clientes c ON v.cliente_id = c.id
WHERE proxima_visita IS NOT NULL
ORDER BY dias_entre_visitas DESC
LIMIT 15;


-- @query: SUM() OVER — soma acumulada (running total)
-- @desc: SUM com OVER calcula a soma ACUMULADA ao invés da soma total.
-- @desc: Mostra como o faturamento vai se acumulando ao longo dos meses.
WITH mensal AS (
    SELECT 
        strftime('%Y-%m', data_hora) AS mes,
        SUM(valor_cobrado) AS receita
    FROM agendamentos 
    WHERE status = 'concluido'
    GROUP BY strftime('%Y-%m', data_hora)
)
SELECT 
    mes,
    receita,
    SUM(receita) OVER (ORDER BY mes) AS receita_acumulada,
    ROUND(SUM(receita) OVER (ORDER BY mes) / ROW_NUMBER() OVER (ORDER BY mes), 2) AS media_acumulada
FROM mensal;


-- @query: AVG() OVER — média móvel de 3 meses
-- @desc: Média móvel suaviza variações e mostra a tendência real.
-- @desc: ROWS BETWEEN define quantas linhas incluir na janela.
WITH diario AS (
    SELECT 
        date(data_hora) AS dia,
        SUM(valor_cobrado) AS receita_dia
    FROM agendamentos 
    WHERE status = 'concluido'
    GROUP BY date(data_hora)
)
SELECT 
    dia,
    receita_dia,
    ROUND(AVG(receita_dia) OVER (
        ORDER BY dia 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS media_movel_7dias
FROM diario
ORDER BY dia DESC
LIMIT 30;


-- @query: NTILE — dividir em quartis
-- @desc: NTILE(4) divide os dados em 4 grupos iguais (quartis).
-- @desc: Útil para segmentar clientes por faixa de gasto.
WITH gastos AS (
    SELECT 
        c.nome,
        SUM(a.valor_cobrado) AS gasto_total,
        COUNT(a.id) AS visitas
    FROM agendamentos a
    JOIN clientes c ON a.cliente_id = c.id
    WHERE a.status = 'concluido'
    GROUP BY a.cliente_id
)
SELECT 
    nome,
    gasto_total,
    visitas,
    NTILE(4) OVER (ORDER BY gasto_total DESC) AS quartil,
    CASE NTILE(4) OVER (ORDER BY gasto_total DESC)
        WHEN 1 THEN 'Premium (Top 25%)'
        WHEN 2 THEN 'Frequente (25-50%)'
        WHEN 3 THEN 'Regular (50-75%)'
        WHEN 4 THEN 'Eventual (75-100%)'
    END AS segmento
FROM gastos
ORDER BY gasto_total DESC;


-- @query: Percentual do total com SUM OVER
-- @desc: Calcula quanto cada serviço representa do total.
-- @desc: SUM() OVER() sem ORDER BY = total geral (todas as linhas).
SELECT 
    s.nome,
    s.categoria,
    SUM(a.valor_cobrado) AS receita,
    SUM(SUM(a.valor_cobrado)) OVER () AS receita_total,
    ROUND(SUM(a.valor_cobrado) * 100.0 / SUM(SUM(a.valor_cobrado)) OVER (), 1) AS pct_do_total,
    SUM(SUM(a.valor_cobrado)) OVER (ORDER BY SUM(a.valor_cobrado) DESC) AS acumulado
FROM agendamentos a
JOIN servicos s ON a.servico_id = s.id
WHERE a.status = 'concluido'
GROUP BY s.id
ORDER BY receita DESC;


-- @query: FIRST_VALUE e LAST_VALUE — extremos da janela
-- @desc: FIRST_VALUE pega o primeiro valor. LAST_VALUE pega o último.
-- @desc: Dentro de cada categoria, qual foi o serviço mais e menos caro?
SELECT DISTINCT
    s.categoria,
    FIRST_VALUE(s.nome) OVER (PARTITION BY s.categoria ORDER BY s.preco DESC) AS mais_caro,
    FIRST_VALUE(s.preco) OVER (PARTITION BY s.categoria ORDER BY s.preco DESC) AS preco_mais_caro,
    FIRST_VALUE(s.nome) OVER (PARTITION BY s.categoria ORDER BY s.preco ASC) AS mais_barato,
    FIRST_VALUE(s.preco) OVER (PARTITION BY s.categoria ORDER BY s.preco ASC) AS preco_mais_barato
FROM servicos s
ORDER BY s.categoria;


-- @query: Múltiplas window functions juntas — dashboard do funcionário
-- @desc: Combina várias funções de janela para criar uma visão completa.
-- @desc: Este tipo de query é o que alimenta dashboards de RH e performance.
SELECT 
    f.nome,
    f.cargo,
    COUNT(a.id) AS atendimentos,
    SUM(a.valor_cobrado) AS receita,
    RANK() OVER (ORDER BY SUM(a.valor_cobrado) DESC) AS rank_receita,
    ROUND(SUM(a.valor_cobrado) * 100.0 / SUM(SUM(a.valor_cobrado)) OVER (), 1) AS pct_receita,
    ROUND(AVG(av.nota), 2) AS nota_media,
    RANK() OVER (ORDER BY AVG(av.nota) DESC) AS rank_satisfacao
FROM agendamentos a
JOIN funcionarios f ON a.funcionario_id = f.id
LEFT JOIN avaliacoes av ON av.agendamento_id = a.id
WHERE a.status = 'concluido'
GROUP BY f.id
ORDER BY receita DESC;
