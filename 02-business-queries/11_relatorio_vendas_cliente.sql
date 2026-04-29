-- Cliente Pleno

-- Reescrita com CTE (evita filesort)
WITH vendas_por_cliente AS (
    SELECT 
        p.cliente_id,
        SUM(p.valor_total) as total_gasto
    FROM pedidos p
    WHERE p.data_pedido > '2024-01-01'
    GROUP BY p.cliente_id
)
SELECT c.nome, v.total_gasto
FROM vendas_por_cliente v
JOIN clientes c ON c.id = v.cliente_id
ORDER BY v.total_gasto DESC;