

-- =====================================================
-- RELATÓRIO 4: SLAs DE ENTREGA POR TRANSPORTADORA
-- =====================================================
WITH analise_entregas AS (
    SELECT 
        e.transportadora,
        e.codigo_rastreio,
        p.id AS pedido_id,
        p.data_pedido,
        e.data_envio,
        e.data_entrega,
        DATEDIFF(e.data_entrega, e.data_envio) AS dias_transporte,
        DATEDIFF(e.data_envio, p.data_pedido) AS dias_separacao,
        DATEDIFF(e.data_entrega, p.data_pedido) AS dias_total_entrega,
        -- SLA tracking
        CASE 
            WHEN DATEDIFF(e.data_entrega, e.data_envio) <= 2 THEN 'No prazo (até 2 dias)'
            WHEN DATEDIFF(e.data_entrega, e.data_envio) <= 5 THEN 'Atraso moderado (3-5 dias)'
            ELSE 'Atraso crítico (>5 dias)'
        END AS status_entrega
    FROM entregas e
    JOIN pedidos p ON e.pedido_id = p.id
    WHERE e.data_entrega IS NOT NULL
      AND p.data_pedido >= DATE_SUB(NOW(), INTERVAL 90 DAY)
)
SELECT 
    transportadora,
    COUNT(*) AS total_entregas,
    ROUND(AVG(dias_transporte), 1) AS media_dias_transporte,
    ROUND(AVG(dias_separacao), 1) AS media_dias_separacao,
    ROUND(AVG(dias_total_entrega), 1) AS media_dias_total,
    -- SLA compliance
    ROUND(SUM(CASE WHEN status_entrega = 'No prazo (até 2 dias)' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS taxa_sla_2dias,
    ROUND(SUM(CASE WHEN status_entrega IN ('No prazo (até 2 dias)', 'Atraso moderado (3-5 dias)') THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS taxa_sla_5dias,
    -- Penalidades
    SUM(CASE WHEN status_entrega = 'Atraso crítico (>5 dias)' THEN 1 ELSE 0 END) AS entregas_com_multa_potencial,
    -- Classificação do parceiro
    CASE 
        WHEN ROUND(SUM(CASE WHEN status_entrega = 'No prazo (até 2 dias)' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) >= 95 
        THEN '⭐ PARCEIRO PREMIUM - Renovar contrato'
        WHEN ROUND(SUM(CASE WHEN status_entrega = 'No prazo (até 2 dias)' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) >= 80 
        THEN '✅ PARCEIRO STANDARD - Monitorar'
        ELSE '⚠️ PARCEIRO CRÍTICO - Reavaliar contrato'
    END AS avaliacao_parceiro,
    -- Custo de insatisfação estimado
    ROUND(SUM(CASE WHEN status_entrega = 'Atraso crítico (>5 dias)' THEN 50 ELSE 0 END), 2) AS custo_cupons_compensacao_estimado
FROM analise_entregas
GROUP BY transportadora
ORDER BY taxa_sla_2dias DESC;