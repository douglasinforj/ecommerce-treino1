SLA de Entrega por Transportadora

SELECT 
    e.transportadora,
    COUNT(*) AS total_entregas,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, e.data_envio, e.data_entrega)), 1) AS horas_media_entrega,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, p.data_pedido, e.data_envio)), 1) AS horas_media_separacao,
    -- SLA (entregues em até 48h)
    ROUND(SUM(CASE WHEN TIMESTAMPDIFF(HOUR, e.data_envio, e.data_entrega) <= 48 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS percentual_sla_48h,
    -- Performance por região (se tivesse CEP, adaptaria)
    COUNT(CASE WHEN e.data_entrega IS NULL AND e.data_envio IS NOT NULL THEN 1 END) AS entregas_em_transito,
    COUNT(CASE WHEN e.data_entrega IS NULL AND e.data_envio IS NULL THEN 1 END) AS entregas_nao_enviadas
FROM entregas e
JOIN pedidos p ON e.pedido_id = p.id
WHERE p.data_pedido >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY e.transportadora
ORDER BY horas_media_entrega ASC;