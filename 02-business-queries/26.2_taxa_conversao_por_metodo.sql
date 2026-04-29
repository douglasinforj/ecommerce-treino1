SELECT 
    pg.forma_pagamento,

    COUNT(*) AS total_transacoes,

    ROUND(AVG(
        TIMESTAMPDIFF(HOUR, p.data_pedido, pg.data_pagamento)
    ), 2) AS tempo_medio_horas,

    ROUND(AVG(
        TIMESTAMPDIFF(MINUTE, p.data_pedido, pg.data_pagamento)
    ), 0) AS tempo_medio_minutos

FROM pagamentos pg
JOIN pedidos p ON pg.pedido_id = p.id

WHERE pg.data_pagamento IS NOT NULL

GROUP BY pg.forma_pagamento
ORDER BY tempo_medio_horas ASC;