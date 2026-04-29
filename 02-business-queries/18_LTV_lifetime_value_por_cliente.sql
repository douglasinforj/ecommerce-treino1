-- Analise individual da vida de cada cliente (Ótimo para CRM, foco no determinado cliente) contendencias e alertas

SELECT 
    c.id,
    c.nome,
    c.email,
    COUNT(DISTINCT p.id) AS total_pedidos,
    SUM(p.valor_total) AS total_gasto,
    ROUND(AVG(p.valor_total), 2) AS ticket_medio,
    DATEDIFF(MAX(p.data_pedido), MIN(p.data_pedido)) AS dias_entre_compras,
    CASE 
        WHEN DATEDIFF(NOW(), MAX(p.data_pedido)) > 90 THEN 'Risco Churn'
        WHEN DATEDIFF(NOW(), MAX(p.data_pedido)) > 30 THEN 'Atenção'
        ELSE 'Cliente Ativo'
    END AS status_relacionamento,
    -- Calcular LTV projetado (média de gasto * frequência média)
    ROUND(SUM(p.valor_total) / COUNT(DISTINCT DATE_FORMAT(p.data_pedido, '%Y-%m')) * 12, 2) AS ltv_anual_projetado
FROM clientes c
JOIN pedidos p ON c.id = p.cliente_id
WHERE p.status IN ('Pago', 'Entregue')
GROUP BY c.id, c.nome, c.email
HAVING total_pedidos >= 1
ORDER BY total_gasto DESC;