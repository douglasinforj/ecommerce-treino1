SELECT 
    pg.forma_pagamento,

    COUNT(DISTINCT p.id) AS pedidos_cancelados,

    ROUND(SUM(p.valor_total), 2) AS receita_perdida,

    ROUND(AVG(p.valor_total), 2) AS ticket_medio_perdido

FROM pedidos p
LEFT JOIN pagamentos pg ON pg.pedido_id = p.id

WHERE p.status = 'Cancelado'

GROUP BY pg.forma_pagamento
ORDER BY receita_perdida DESC;