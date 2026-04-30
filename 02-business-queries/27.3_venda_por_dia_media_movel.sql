
/*
média móvel por dia (não por hora):

Essa query analisa padrões temporais de vendas, incluindo sazonalidade semanal, comportamento por hora e tendência através de média móvel de 30 dias.
*/

WITH base AS (
    SELECT 
        DATE(data_pedido) AS dia,
        COUNT(*) AS total_pedidos
    FROM pedidos
    WHERE data_pedido >= DATE_SUB(NOW(), INTERVAL 180 DAY)
      AND status NOT IN ('Cancelado')
    GROUP BY dia
)

SELECT 
    dia,
    total_pedidos,
    ROUND(
        AVG(total_pedidos) OVER (
            ORDER BY dia 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ), 1
    ) AS media_movel_30dias
FROM base;