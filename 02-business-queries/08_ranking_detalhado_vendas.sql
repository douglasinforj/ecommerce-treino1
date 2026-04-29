-- Top 10 com análise de tendência
SELECT 
    p.nome,
    p.categoria,
    SUM(ip.quantidade) AS unidades_vendidas,
    ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS receita,
    ROUND(AVG(ip.preco_unitario), 2) AS preco_medio_venda,
    ROUND((p.preco_venda - p.preco_custo) / p.preco_venda * 100, 2) AS margem_atual,
    -- Tendência (últimas 4 semanas vs anteriores)
    SUM(CASE WHEN ped.data_pedido >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN ip.quantidade ELSE 0 END) AS vendas_ultimas_4semanas,
    SUM(CASE WHEN ped.data_pedido < DATE_SUB(NOW(), INTERVAL 30 DAY) THEN ip.quantidade ELSE 0 END) AS vendas_anteriores,
    -- Classificação para ação
    CASE 
        WHEN SUM(ip.quantidade) > 100 AND ROUND((p.preco_venda - p.preco_custo) / p.preco_venda * 100, 2) > 30 
        THEN '🔥 CAMPEÃO DE VENDAS'
        WHEN SUM(ip.quantidade) > 50 AND ROUND((p.preco_venda - p.preco_custo) / p.preco_venda * 100, 2) < 15 
        THEN '💰 OPORTUNIDADE DE LUCRO'
        WHEN SUM(ip.quantidade) < 10 AND p.estoque_atual > 100 
        THEN '⚠️ ESTOQUE PARADO'
        WHEN SUM(CASE WHEN ped.data_pedido >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN ip.quantidade ELSE 0 END) >
             SUM(CASE WHEN ped.data_pedido < DATE_SUB(NOW(), INTERVAL 30 DAY) THEN ip.quantidade ELSE 0 END) * 1.5
        THEN '📈 PRODUTO EM ALTA'
        ELSE '✅ MANUTENÇÃO'
    END AS status_produto
FROM produtos p
JOIN itens_pedido ip ON p.id = ip.produto_id
JOIN pedidos ped ON ip.pedido_id = ped.id
WHERE ped.status IN ('Pago', 'Entregue')
GROUP BY p.id, p.nome, p.categoria, p.preco_venda, p.preco_custo, p.estoque_atual
ORDER BY receita DESC
LIMIT 20;