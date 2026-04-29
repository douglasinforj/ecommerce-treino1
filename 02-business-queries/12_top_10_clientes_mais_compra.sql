-- Top 10% clientes que mais compram (Decis de Pareto)

WITH cliente_gasto AS (
    SELECT 
        c.id,
        c.nome,
        SUM(p.valor_total) AS total_gasto,
        NTILE(10) OVER (ORDER BY SUM(p.valor_total) DESC) AS decil_gasto
    FROM clientes c
    JOIN pedidos p ON c.id = p.cliente_id
    WHERE p.status IN ('Pago', 'Entregue')
    GROUP BY c.id, c.nome
)
SELECT 
    *,
    CASE 
        WHEN decil_gasto = 1 THEN 'Top 10% (VIP)'
        WHEN decil_gasto = 2 THEN 'Top 20% (Alto Valor)'
        WHEN decil_gasto BETWEEN 3 AND 5 THEN 'Médio Valor'
        ELSE 'Baixo Valor'
    END AS segmento_cliente
FROM cliente_gasto
WHERE decil_gasto <= 2 -- Mostrar só top 20%
ORDER BY total_gasto DESC;