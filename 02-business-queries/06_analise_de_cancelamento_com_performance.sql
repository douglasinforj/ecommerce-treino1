-- =====================================================
-- VERSÃO PROFISSIONAL - Otimizada e com índices
-- =====================================================

-- Primeiro, crie índices para performance
CREATE INDEX idx_pedidos_data_status ON pedidos(data_pedido, status);
CREATE INDEX idx_pedidos_valor ON pedidos(valor_total);

-- Query otimizada
WITH 
-- Filtrar pedidos uma única vez
pedidos_filtrados AS (
    SELECT 
        id,
        cliente_id,
        valor_total,
        data_pedido,
        status
    FROM pedidos
    WHERE data_pedido >= DATE_SUB(NOW(), INTERVAL 30 DAY)
),
-- Pagamentos (LEFT JOIN para não perder pedidos)
pagamentos_info AS (
    SELECT 
        pedido_id,
        forma_pagamento,
        parcelas
    FROM pagamentos
),
-- Combinar dados
base_analise AS (
    SELECT 
        pf.*,
        pi.forma_pagamento,
        pi.parcelas,
        CASE 
            WHEN pf.valor_total < 100 THEN 'Até R$100'
            WHEN pf.valor_total < 500 THEN 'R$100-R$500'
            WHEN pf.valor_total < 1000 THEN 'R$500-R$1000'
            ELSE 'Acima de R$1000'
        END AS faixa_valor,
        EXTRACT(HOUR FROM pf.data_pedido) AS hora_pedido
    FROM pedidos_filtrados pf
    LEFT JOIN pagamentos_info pi ON pf.id = pi.pedido_id
)
-- Agora as análises
SELECT * FROM (
    -- VISÃO GERAL
    SELECT 
        1 AS ordem,
        'VISÃO GERAL' AS tipo_analise,
        'Todos os pedidos' AS segmento,
        COUNT(*) AS total_pedidos,
        SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) AS total_cancelados,
        ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS taxa_cancelamento,
        ROUND(AVG(CASE WHEN status = 'Cancelado' THEN valor_total ELSE NULL END), 2) AS valor_medio_cancelado,
        '' AS acao_recomendada
    FROM base_analise
    
    UNION ALL
    
    -- POR PAGAMENTO
    SELECT 
        2 AS ordem,
        'POR PAGAMENTO',
        COALESCE(forma_pagamento, 'Não informado'),
        COUNT(*),
        SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END),
        ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2),
        ROUND(AVG(CASE WHEN status = 'Cancelado' THEN valor_total ELSE NULL END), 2),
        CASE 
            WHEN ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) > 15 
                 AND COALESCE(forma_pagamento, 'Não informado') = 'Boleto' 
            THEN '🔴 Reavaliar política de boletos'
            WHEN ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) > 15 
                 AND COALESCE(forma_pagamento, 'Não informado') = 'Cartao' 
            THEN '⚠️ Verificar antifraude'
            ELSE '✅ OK'
        END
    FROM base_analise
    GROUP BY forma_pagamento
    
    UNION ALL
    
    -- POR FAIXA DE VALOR
    SELECT 
        3 AS ordem,
        'POR VALOR',
        faixa_valor,
        COUNT(*),
        SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END),
        ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2),
        ROUND(AVG(CASE WHEN status = 'Cancelado' THEN valor_total ELSE NULL END), 2),
        CASE 
            WHEN ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) > 20 
                 AND faixa_valor = 'Acima de R$1000'
            THEN '🔴 Revisar pedidos de alto valor'
            WHEN ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) > 20 
            THEN '🟡 Oferecer incentivo'
            ELSE '✅ OK'
        END
    FROM base_analise
    GROUP BY faixa_valor
    
    UNION ALL
    
    -- POR HORÁRIO
    SELECT 
        4 AS ordem,
        'POR HORARIO',
        CONCAT(hora_pedido, 'h - ', hora_pedido + 1, 'h'),
        COUNT(*),
        SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END),
        ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2),
        ROUND(AVG(CASE WHEN status = 'Cancelado' THEN valor_total ELSE NULL END), 2),
        CASE 
            WHEN hora_pedido BETWEEN 0 AND 6 THEN '🌙 Cancelamento noturno - Verificar fraude'
            WHEN hora_pedido BETWEEN 12 AND 14 THEN '🍽️ Horário de almoço - Compra por impulso'
            ELSE '✅ Padrão normal'
        END
    FROM base_analise
    GROUP BY hora_pedido
) AS resultados
ORDER BY ordem, taxa_cancelamento DESC;