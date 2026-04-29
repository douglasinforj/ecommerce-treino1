

/*
Churn / Cancelamentos / Risco Operacional

mede taxa de cancelamento
identifica produtos problemáticos
foca em perda de venda / fricção

*/


SELECT 
    p.id,
    p.nome,
    p.categoria,
    COUNT(CASE WHEN ped.status = 'Cancelado' THEN 1 END) AS total_cancelamentos,
    COUNT(ped.id) AS total_pedidos_contendo_produto,
    ROUND(COUNT(CASE WHEN ped.status = 'Cancelado' THEN 1 END) / COUNT(ped.id) * 100, 2) AS taxa_cancelamento,
    ROUND(AVG(ped.valor_total), 2) AS ticket_medio_cancelamento
FROM produtos p
JOIN itens_pedido ip ON p.id = ip.produto_id
JOIN pedidos ped ON ip.pedido_id = ped.id
GROUP BY p.id, p.nome, p.categoria
HAVING total_pedidos_contendo_produto >= 5
ORDER BY taxa_cancelamento DESC
LIMIT 20;