/*

Não é ROI direto
É análise de pagamentos / conversão
Impacta receita e eficiência

*/



SELECT 
    pg.forma_pagamento,

    COUNT(DISTINCT pg.pedido_id) AS total_transacoes,

    ROUND(SUM(pg.valor_pago), 2) AS valor_total_pago,

    ROUND(AVG(pg.parcelas), 1) AS media_parcelas,

    ROUND(
        COUNT(DISTINCT pg.pedido_id) * 1.0 /
        (SELECT COUNT(*) FROM pedidos),
    2) AS taxa_aprovacao,

    ROUND(
        AVG(
            CASE 
                WHEN pg.data_pagamento IS NOT NULL 
                THEN TIMESTAMPDIFF(HOUR, p.data_pedido, pg.data_pagamento)
            END
        ),
    1) AS horas_para_pagamento,

    ROUND(
        AVG(pg.valor_pago / NULLIF(pg.parcelas, 0)),
    2) AS valor_medio_parcela

FROM pagamentos pg
JOIN pedidos p ON pg.pedido_id = p.id

GROUP BY pg.forma_pagamento
ORDER BY valor_total_pago DESC;