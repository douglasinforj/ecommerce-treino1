-- =====================================================
-- NÁLISE DE CANCELAMENTO POR PERFIL
-- =====================================================
WITH analise_cancelamento AS (
    SELECT 
        p.id AS pedido_id,
        p.cliente_id,
        p.valor_total,
        p.data_pedido,
        p.status,
        pg.forma_pagamento,
        pg.parcelas,
        COUNT(ip.produto_id) AS qtd_produtos,
        CASE 
            WHEN p.status = 'Cancelado' 
            THEN TIMESTAMPDIFF(HOUR, p.data_pedido, NOW())
            ELSE NULL
        END AS horas_para_cancelamento
    FROM pedidos p
    LEFT JOIN pagamentos pg ON p.id = pg.pedido_id
    LEFT JOIN itens_pedido ip ON p.id = ip.pedido_id
    WHERE p.data_pedido >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY p.id, p.cliente_id, p.valor_total, p.data_pedido, p.status, pg.forma_pagamento, pg.parcelas
),
-- PRIMEIRA CORREÇÃO: Pré-calcular a faixa de valor
analise_com_faixa AS (
    SELECT 
        *,
        CASE 
            WHEN valor_total < 100 THEN 'Até R$100'
            WHEN valor_total < 500 THEN 'R$100-R$500'
            WHEN valor_total < 1000 THEN 'R$500-R$1000'
            ELSE 'Acima de R$1000'
        END AS faixa_valor,
        EXTRACT(HOUR FROM data_pedido) AS hora_pedido
    FROM analise_cancelamento
)
-- VISÃO GERAL
SELECT 
    'VISÃO GERAL' AS tipo_analise,
    'Todos os pedidos' AS segmento,
    COUNT(*) AS total_pedidos,
    SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) AS total_cancelados,
    ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS taxa_cancelamento,
    ROUND(AVG(CASE WHEN status = 'Cancelado' THEN valor_total ELSE NULL END), 2) AS valor_medio_cancelado,
    '' AS acao_recomendada
FROM analise_com_faixa

UNION ALL

-- CANCELAMENTO POR FORMA DE PAGAMENTO
SELECT 
    'POR PAGAMENTO' AS tipo_analise,
    COALESCE(forma_pagamento, 'Não informado') AS segmento,
    COUNT(*) AS total_pedidos,
    SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) AS total_cancelados,
    ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS taxa_cancelamento,
    ROUND(AVG(CASE WHEN status = 'Cancelado' THEN valor_total ELSE NULL END), 2) AS valor_medio_cancelado,
    CASE 
        WHEN ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) > 15 
             AND COALESCE(forma_pagamento, 'Não informado') = 'Boleto' 
        THEN '🔴 Reavaliar política de boletos - Alta taxa de desistência'
        WHEN ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) > 15 
             AND COALESCE(forma_pagamento, 'Não informado') = 'Cartao' 
        THEN '⚠️ Verificar antifraude - Possível chargeback'
        ELSE '✅ OK'
    END AS acao_recomendada
FROM analise_com_faixa
GROUP BY forma_pagamento

UNION ALL

-- CANCELAMENTO POR FAIXA DE VALOR (CORRIGIDO)
SELECT 
    'POR VALOR' AS tipo_analise,
    faixa_valor AS segmento,
    COUNT(*) AS total_pedidos,
    SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) AS total_cancelados,
    ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS taxa_cancelamento,
    -- CORRIGIDO: Agora usa a faixa diretamente
    ROUND(AVG(CASE WHEN status = 'Cancelado' THEN valor_total ELSE NULL END), 2) AS valor_medio_cancelado,
    CASE 
        WHEN ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) > 20 
             AND faixa_valor = 'Acima de R$1000'
        THEN '🔴 Revisar política para pedidos de alto valor'
        WHEN ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) > 20 
        THEN '🟡 Oferecer incentivo para finalização'
        ELSE '✅ OK'
    END AS acao_recomendada
FROM analise_com_faixa
GROUP BY faixa_valor

UNION ALL

-- CANCELAMENTO POR HORÁRIO (CORRIGIDO)
SELECT 
    'POR HORARIO' AS tipo_analise,
    CONCAT(hora_pedido, 'h - ', hora_pedido + 1, 'h') AS segmento,
    COUNT(*) AS total_pedidos,
    SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) AS total_cancelados,
    ROUND(SUM(CASE WHEN status = 'Cancelado' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS taxa_cancelamento,
    ROUND(AVG(CASE WHEN status = 'Cancelado' THEN valor_total ELSE NULL END), 2) AS valor_medio_cancelado,
    CASE 
        WHEN hora_pedido BETWEEN 0 AND 6 THEN '🌙 Cancelamento noturno - Verificar fraude'
        WHEN hora_pedido BETWEEN 12 AND 14 THEN '🍽️ Horário de almoço - Possível compra por impulso'
        ELSE '✅ Padrão normal'
    END AS acao_recomendada
FROM analise_com_faixa
GROUP BY hora_pedido
ORDER BY 
    CASE tipo_analise
        WHEN 'VISÃO GERAL' THEN 1
        WHEN 'POR PAGAMENTO' THEN 2
        WHEN 'POR VALOR' THEN 3
        WHEN 'POR HORARIO' THEN 4
    END,
    taxa_cancelamento DESC;