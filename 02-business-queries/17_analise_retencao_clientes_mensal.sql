/*
Taxa de clientes que voltam a comprar no mês seguinte
Cohort Analysis - Retenção de Clientes por Mês
*/

WITH primeira_compra AS (
    SELECT 
        cliente_id,
        DATE_FORMAT(MIN(data_pedido), '%Y-%m-01') AS mes_primeira_compra
    FROM pedidos
    WHERE status NOT IN ('Cancelado')
    GROUP BY cliente_id
),
todas_compras AS (
    SELECT 
        p.cliente_id,
        DATE_FORMAT(p.data_pedido, '%Y-%m-01') AS mes_compra,
        pc.mes_primeira_compra,
        TIMESTAMPDIFF(MONTH, pc.mes_primeira_compra, DATE_FORMAT(p.data_pedido, '%Y-%m-01')) AS mes_cohort
    FROM pedidos p
    JOIN primeira_compra pc ON p.cliente_id = pc.cliente_id
    WHERE p.status NOT IN ('Cancelado')
)
SELECT 
    mes_primeira_compra,
    mes_cohort,
    COUNT(DISTINCT cliente_id) AS clientes_ativos,
    LAG(COUNT(DISTINCT cliente_id)) OVER (PARTITION BY mes_primeira_compra ORDER BY mes_cohort) AS clientes_mes_anterior,
    ROUND(COUNT(DISTINCT cliente_id) / 
          FIRST_VALUE(COUNT(DISTINCT cliente_id)) OVER (PARTITION BY mes_primeira_compra ORDER BY mes_cohort) * 100, 2) AS taxa_retencao
FROM todas_compras
GROUP BY mes_primeira_compra, mes_cohort
ORDER BY mes_primeira_compra, mes_cohort;