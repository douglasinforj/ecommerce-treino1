
-- Painel de KPIs em uma Query (Para sistemas ou BI)

SELECT 
    'Métricas do Dia' AS tipo_metrica,
    COUNT(DISTINCT p.id) AS pedidos_hoje,
    ROUND(SUM(p.valor_total), 2) AS faturamento_hoje,
    ROUND(AVG(p.valor_total), 2) AS ticket_medio_hoje,
    COUNT(DISTINCT c.id) AS clientes_ativos_hoje,
    -- Meta do dia (exemplo: R$ 10.000)
    ROUND((SUM(p.valor_total) / 10000) * 100, 2) AS percentual_meta_dia,
    -- Comparação com dia anterior
    ROUND((SUM(p.valor_total) - LAG(SUM(p.valor_total)) OVER (ORDER BY CURDATE())) / LAG(SUM(p.valor_total)) OVER (ORDER BY CURDATE()) * 100, 2) AS variacao_dia_anterior
FROM pedidos p
LEFT JOIN clientes c ON p.cliente_id = c.id
WHERE DATE(p.data_pedido) = CURDATE()
  AND p.status NOT IN ('Cancelado')

UNION ALL

SELECT 
    'Métricas do Mês (MTD)',
    COUNT(DISTINCT p.id),
    ROUND(SUM(p.valor_total), 2),
    ROUND(AVG(p.valor_total), 2),
    COUNT(DISTINCT c.id),
    ROUND((SUM(p.valor_total) / 200000) * 100, 2), -- Meta mensal: R$ 200k
    NULL
FROM pedidos p
LEFT JOIN clientes c ON p.cliente_id = c.id
WHERE MONTH(p.data_pedido) = MONTH(CURDATE())
  AND YEAR(p.data_pedido) = YEAR(CURDATE())
  AND p.status NOT IN ('Cancelado');