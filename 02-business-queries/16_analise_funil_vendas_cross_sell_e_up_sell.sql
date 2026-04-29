

/* 

Pares de produtos mais comprados juntos
Produtos Frequentemente Comprados Juntos (Market Basket Analysis)
Essa query implementa uma análise de Market Basket, identificando produtos frequentemente comprados 
juntos e calculando a confiança da associação, com foco em estratégias de cross-sell para aumento de LTV e AOV.



*/
SELECT 
    p1.nome AS produto_1,
    p2.nome AS produto_2,
    COUNT(*) AS vezes_comprados_juntos,
    -- Calcular confiança da regra
    ROUND(COUNT(*) / (SELECT COUNT(DISTINCT pedido_id) FROM itens_pedido WHERE produto_id = p1.id) * 100, 2) AS confianca
FROM itens_pedido ip1
JOIN itens_pedido ip2 ON ip1.pedido_id = ip2.pedido_id AND ip1.produto_id < ip2.produto_id
JOIN produtos p1 ON ip1.produto_id = p1.id
JOIN produtos p2 ON ip2.produto_id = p2.id
JOIN pedidos ped ON ip1.pedido_id = ped.id
WHERE ped.status IN ('Pago', 'Entregue')
  AND ped.data_pedido >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY p1.id, p2.id, p1.nome, p2.nome
HAVING vezes_comprados_juntos >= 3
ORDER BY vezes_comprados_juntos DESC
LIMIT 30;