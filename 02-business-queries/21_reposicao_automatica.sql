/*

Reposição automática (sugestão de compra)

*/


WITH vendas_diarias AS (
    SELECT 
        ip.produto_id,
        SUM(ip.quantidade) AS total_vendido,
        GREATEST(DATEDIFF(MAX(p.data_pedido), MIN(p.data_pedido)), 1) AS dias
    FROM itens_pedido ip
    JOIN pedidos p ON ip.pedido_id = p.id
    WHERE p.status IN ('Pago', 'Entregue')
    GROUP BY ip.produto_id
),

consumo AS (
    SELECT 
        produto_id,
        total_vendido / dias AS consumo_medio_dia
    FROM vendas_diarias
)

SELECT 
    pr.id,
    pr.nome,
    pr.estoque_atual,
    c.consumo_medio_dia,

    -- Cobertura em dias
    ROUND(pr.estoque_atual / NULLIF(c.consumo_medio_dia, 0), 1) AS dias_cobertura,

    -- Sugestão: manter 30 dias de estoque
    ROUND((c.consumo_medio_dia * 30) - pr.estoque_atual, 0) AS sugestao_compra

FROM produtos pr
LEFT JOIN consumo c ON pr.id = c.produto_id
ORDER BY dias_cobertura ASC;