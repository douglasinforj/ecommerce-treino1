SELECT 
    pg.forma_pagamento,

    COUNT(DISTINCT p.id) AS total_pedidos,

    COUNT(DISTINCT CASE 
        WHEN p.status IN ('Pago', 'Enviado', 'Entregue') 
        THEN p.id 
    END) AS aprovados,

    COUNT(DISTINCT CASE 
        WHEN p.status = 'Cancelado' 
        THEN p.id 
    END) AS falhas,

    ROUND(
        COUNT(DISTINCT CASE WHEN p.status = 'Cancelado' THEN p.id END) * 1.0 /
        COUNT(DISTINCT p.id) * 100,
    2) AS taxa_falha_percentual

FROM pedidos p
LEFT JOIN pagamentos pg ON pg.pedido_id = p.id

GROUP BY pg.forma_pagamento
ORDER BY taxa_falha_percentual DESC;