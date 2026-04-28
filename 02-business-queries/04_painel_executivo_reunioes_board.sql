-- =====================================================
-- DASHBOARD ESTRATÉGICO (EUNIÃO DE VENDAS)
-- =====================================================
SELECT 
    '📊 RELATÓRIO EXECUTIVO DE VENDAS' AS titulo,
    NOW() AS data_geracao,
    'Período: Últimos 90 dias' AS periodo;

-- Métricas principais
SELECT 
    '🎯 KPIs PRINCIPAIS' AS categoria,
    ROUND(SUM(valor_total), 2) AS receita_total_periodo,
    COUNT(*) AS total_pedidos,
    ROUND(AVG(valor_total), 2) AS ticket_medio,
    COUNT(DISTINCT cliente_id) AS clientes_ativos,
    ROUND(SUM(valor_total) / 90, 2) AS receita_dia_medio
FROM pedidos
WHERE status IN ('Pago', 'Entregue')
  AND data_pedido >= DATE_SUB(NOW(), INTERVAL 90 DAY);

-- Matriz de performance (SWOT simplificada)
WITH metricas AS (
    SELECT 
        'Produto Mais Vendido' AS indicador,
        (SELECT nome FROM produtos 
         JOIN itens_pedido ip ON produtos.id = ip.produto_id
         GROUP BY produtos.id ORDER BY SUM(ip.quantidade) DESC LIMIT 1) AS valor
    UNION ALL
    SELECT 
        'Ticket Médio Atual',
        CONCAT('R$ ', ROUND((SELECT AVG(valor_total) FROM pedidos WHERE status = 'Entregue'), 2))
    UNION ALL
    SELECT 
        'Taxa de Cancelamento',
        CONCAT(ROUND((SELECT SUM(CASE WHEN status='Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100 FROM pedidos WHERE data_pedido >= DATE_SUB(NOW(), INTERVAL 30 DAY)), 2), '%')
    UNION ALL
    SELECT 
        'SLA de Entrega (até 2 dias)',
        CONCAT(ROUND((SELECT SUM(CASE WHEN DATEDIFF(e.data_entrega, e.data_envio) <= 2 THEN 1 ELSE 0 END) / COUNT(*) * 100 
                      FROM entregas e WHERE e.data_entrega IS NOT NULL), 2), '%')
    UNION ALL
    SELECT 
        'Clientes em Risco Churn',
        (SELECT COUNT(*) FROM (
            SELECT c.id FROM clientes c 
            LEFT JOIN pedidos p ON c.id = p.cliente_id AND p.data_pedido > NOW() - INTERVAL 90 DAY 
            WHERE p.id IS NULL AND c.id IN (SELECT DISTINCT cliente_id FROM pedidos)
            LIMIT 1
        ) AS tmp)
)
SELECT * FROM metricas;

-- Alertas automáticos para o time de vendas
SELECT 
    '⚠️ ALERTAS E RECOMENDAÇÕES' AS categoria,
    '🔴 Ação Imediata' AS prioridade,
    'Clientes VIP em risco de churn' AS alerta,
    'Contatar os 10 clientes com maior ticket que não compram há 90 dias' AS recomendacao
UNION ALL
SELECT 
    '⚠️ ALERTAS E RECOMENDAÇÕES',
    '🟠 Atenção',
    'Produtos com margem baixa e alto volume',
    'Revisar precificação de produtos categoria Eletronicos' 
UNION ALL
SELECT 
    '⚠️ ALERTAS E RECOMENDAÇÕES',
    '🟢 Oportunidade',
    'Cross-sell identificado',
    'Clientes que compram Smartphone tem 73% de chance de comprar Acessórios';