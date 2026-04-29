-- =====================================================
-- RELATÓRIO 1: TICKET MÉDIO COM ANÁLISE DE TENDÊNCIA
-- =====================================================

WITH metricas_periodo AS (
    SELECT 
        CASE 
            WHEN data_pedido >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 'Última Semana'
            WHEN data_pedido >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 'Último Mês'
            WHEN data_pedido >= DATE_SUB(NOW(), INTERVAL 90 DAY) THEN 'Último Trimestre'
            ELSE 'Período Anterior'
        END AS periodo,
        COUNT(*) AS qtd_pedidos,
        ROUND(AVG(valor_total), 2) AS ticket_medio,
        ROUND(MIN(valor_total), 2) AS menor_ticket,
        ROUND(MAX(valor_total), 2) AS maior_ticket,
        ROUND(STDDEV(valor_total), 2) AS desvio_padrao
    FROM pedidos
    WHERE status = 'Entregue'
      AND data_pedido >= DATE_SUB(NOW(), INTERVAL 180 DAY)
    GROUP BY periodo
),
-- Calcular percentis separadamente (MySQL não tem PERCENTILE_CONT)
percentis AS (
    SELECT 
        'Última Semana' AS periodo,
        ROUND(MAX(CASE WHEN seq <= total * 0.25 THEN valor_total END), 2) AS p25,
        ROUND(MAX(CASE WHEN seq <= total * 0.50 THEN valor_total END), 2) AS p50_mediana,
        ROUND(MAX(CASE WHEN seq <= total * 0.75 THEN valor_total END), 2) AS p75,
        ROUND(MAX(CASE WHEN seq <= total * 0.90 THEN valor_total END), 2) AS p90
    FROM (
        SELECT 
            valor_total,
            ROW_NUMBER() OVER (ORDER BY valor_total) AS seq,
            COUNT(*) OVER () AS total
        FROM pedidos
        WHERE status = 'Entregue'
          AND data_pedido >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ) AS t
    
    UNION ALL
    
    SELECT 
        'Último Mês',
        ROUND(MAX(CASE WHEN seq <= total * 0.25 THEN valor_total END), 2),
        ROUND(MAX(CASE WHEN seq <= total * 0.50 THEN valor_total END), 2),
        ROUND(MAX(CASE WHEN seq <= total * 0.75 THEN valor_total END), 2),
        ROUND(MAX(CASE WHEN seq <= total * 0.90 THEN valor_total END), 2)
    FROM (
        SELECT 
            valor_total,
            ROW_NUMBER() OVER (ORDER BY valor_total) AS seq,
            COUNT(*) OVER () AS total
        FROM pedidos
        WHERE status = 'Entregue'
          AND data_pedido >= DATE_SUB(NOW(), INTERVAL 30 DAY)
          AND data_pedido < DATE_SUB(NOW(), INTERVAL 7 DAY)
    ) AS t
    
    UNION ALL
    
    SELECT 
        'Último Trimestre',
        ROUND(MAX(CASE WHEN seq <= total * 0.25 THEN valor_total END), 2),
        ROUND(MAX(CASE WHEN seq <= total * 0.50 THEN valor_total END), 2),
        ROUND(MAX(CASE WHEN seq <= total * 0.75 THEN valor_total END), 2),
        ROUND(MAX(CASE WHEN seq <= total * 0.90 THEN valor_total END), 2)
    FROM (
        SELECT 
            valor_total,
            ROW_NUMBER() OVER (ORDER BY valor_total) AS seq,
            COUNT(*) OVER () AS total
        FROM pedidos
        WHERE status = 'Entregue'
          AND data_pedido >= DATE_SUB(NOW(), INTERVAL 90 DAY)
          AND data_pedido < DATE_SUB(NOW(), INTERVAL 30 DAY)
    ) AS t
)
SELECT 
    mp.periodo,
    mp.qtd_pedidos,
    mp.ticket_medio,
    mp.menor_ticket,
    mp.maior_ticket,
    mp.desvio_padrao,
    COALESCE(p.p25, 0) AS percentil_25,
    COALESCE(p.p50_mediana, 0) AS mediana,
    COALESCE(p.p75, 0) AS percentil_75,
    COALESCE(p.p90, 0) AS percentil_90,
    -- Classificação de saúde do negócio
    CASE 
        WHEN mp.ticket_medio > (SELECT AVG(ticket_medio) FROM metricas_periodo WHERE periodo = 'Último Trimestre') * 1.1 
        THEN '🚀 Excelente - Ticket acima da média'
        WHEN mp.ticket_medio < (SELECT AVG(ticket_medio) FROM metricas_periodo WHERE periodo = 'Último Trimestre') * 0.9 
        THEN '⚠️ Atenção - Ticket abaixo da média'
        ELSE '✅ Estável'
    END AS analise_ticket,
    -- Recomendação
    CASE 
        WHEN mp.ticket_medio < 100 THEN '🔴 Ticket baixo - Ofertas de upsell necessárias'
        WHEN mp.ticket_medio BETWEEN 100 AND 500 THEN '🟡 Ticket médio - Potencial para cross-sell'
        WHEN mp.ticket_medio > 500 THEN '🟢 Ticket alto - Manter estratégia premium'
    END AS recomendacao_vendas
FROM metricas_periodo mp
LEFT JOIN percentis p ON mp.periodo = p.periodo
ORDER BY 
    CASE mp.periodo
        WHEN 'Última Semana' THEN 1
        WHEN 'Último Mês' THEN 2
        WHEN 'Último Trimestre' THEN 3
        ELSE 4
    END;