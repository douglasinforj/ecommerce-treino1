-- =====================================================
-- VERSÃO PROFISSIONAL - Com análise de variação de preço
-- =====================================================
WITH precos_diferentes AS (
    -- Identificar produtos que tiveram preços diferentes
    SELECT 
        p.id,
        p.nome,
        COUNT(DISTINCT ip.preco_unitario) AS qtd_precos_diferentes,
        MIN(ip.preco_unitario) AS menor_preco_vendido,
        MAX(ip.preco_unitario) AS maior_preco_vendido,
        ROUND(AVG(ip.preco_unitario), 2) AS preco_medio_vendido
    FROM produtos p
    JOIN itens_pedido ip ON p.id = ip.produto_id
    GROUP BY p.id, p.nome
    HAVING qtd_precos_diferentes > 1
),
vendas_produtos AS (
    SELECT 
        p.id,
        p.nome,
        p.categoria,
        p.preco_venda,
        p.preco_custo,
        SUM(ip.quantidade) AS unidades_vendidas,
        ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS receita_total,
        ROUND(SUM(ip.quantidade * (ip.preco_unitario - p.preco_custo)), 2) AS lucro_total,
        -- Margem REAL (média ponderada)
        ROUND((SUM(ip.quantidade * (ip.preco_unitario - p.preco_custo)) / 
               NULLIF(SUM(ip.quantidade * ip.preco_unitario), 0)) * 100, 2) AS margem_percentual,
        -- Margem esperada (baseada no preço de venda)
        ROUND((p.preco_venda - p.preco_custo) / NULLIF(p.preco_venda, 0) * 100, 2) AS margem_teorica,
        COUNT(DISTINCT ip.pedido_id) AS qtd_pedidos,
        COUNT(DISTINCT ip.preco_unitario) AS variacoes_preco
    FROM produtos p
    JOIN itens_pedido ip ON p.id = ip.produto_id
    JOIN pedidos ped ON ip.pedido_id = ped.id
    WHERE ped.status IN ('Pago', 'Entregue')
      AND ped.data_pedido >= DATE_SUB(NOW(), INTERVAL 90 DAY)
    GROUP BY p.id, p.nome, p.categoria, p.preco_venda, p.preco_custo
),
classificacao_abc AS (
    SELECT 
        *,
        SUM(receita_total) OVER () AS receita_total_geral,
        ROUND(SUM(receita_total) OVER (ORDER BY receita_total DESC) / 
              NULLIF(SUM(receita_total) OVER (), 0) * 100, 2) AS receita_acumulada_percentual,
        -- Classificação ABC com critérios claros
        CASE 
            WHEN SUM(receita_total) OVER (ORDER BY receita_total DESC) / 
                 NULLIF(SUM(receita_total) OVER (), 0) <= 0.8 THEN 'A (Top 20% produtos)'
            WHEN SUM(receita_total) OVER (ORDER BY receita_total DESC) / 
                 NULLIF(SUM(receita_total) OVER (), 0) <= 0.95 THEN 'B (Próximos 30% produtos)'
            ELSE 'C (Últimos 50% produtos)'
        END AS classificacao_abc
    FROM vendas_produtos
)
SELECT 
    classificacao_abc,
    categoria,
    COUNT(*) AS qtd_produtos,
    ROUND(SUM(receita_total), 2) AS receita_total,
    ROUND(SUM(lucro_total), 2) AS lucro_total,
    ROUND(AVG(margem_percentual), 2) AS margem_real_media,
    ROUND(AVG(margem_teorica), 2) AS margem_teorica_media,
    ROUND(AVG(margem_percentual) - AVG(margem_teorica), 2) AS margem_erodida,
    -- Alerta de produtos com preço inconsistente
    SUM(CASE WHEN variacoes_preco > 1 THEN 1 ELSE 0 END) AS produtos_com_precos_variados,
    -- Recomendações estratégicas (MAIS ROBUSTA)
    CASE 
        -- Estrelas (ALTA receita + ALTA margem)
        WHEN classificacao_abc IN ('A (Top 20% produtos)', 'B (Próximos 30% produtos)') 
             AND AVG(margem_percentual) > 30 
        THEN '🌟 PRODUTO ESTRELA - Priorizar estoque e marketing'
        
        -- Vaca leiteira (ALTA receita + BAIXA margem)
        WHEN classificacao_abc IN ('A (Top 20% produtos)', 'B (Próximos 30% produtos)') 
             AND AVG(margem_percentual) BETWEEN 15 AND 30 
        THEN '💰 VACA LEITEIRA - Otimizar custos para aumentar margem'
        
        -- Volume (ALTA receita + MARGEM NEGATIVA/BAIXA)
        WHEN classificacao_abc IN ('A (Top 20% produtos)', 'B (Próximos 30% produtos)') 
             AND AVG(margem_percentual) < 15 
        THEN '⚠️ PRODUTO VOLUME - Revisar precificação URGENTE'
        
        -- Potencial de crescimento (BAIXA receita + ALTA margem)
        WHEN classificacao_abc = 'C (Últimos 50% produtos)' 
             AND AVG(margem_percentual) > 30 
        THEN '📈 POTENCIAL INEXPLORADO - Investir em marketing'
        
        -- Abacaxi (BAIXA receita + BAIXA margem)
        WHEN classificacao_abc = 'C (Últimos 50% produtos)' 
             AND AVG(margem_percentual) < 10 
        THEN '🍎 PRODUTO ZUMBI - Considerar descontinuar ou liquidar'
        
        -- Produtos com preço inconsistente (alerta especial)
        WHEN SUM(CASE WHEN variacoes_preco > 1 THEN 1 ELSE 0 END) > 0 
             AND AVG(margem_percentual) < AVG(margem_teorica) - 10
        THEN '🚨 ALERTA: Produtos vendendo abaixo do preço - Revisar promoções'
        
        ELSE '🔄 MANUTENÇÃO PADRÃO'
    END AS estrategia_recomendada,
    -- ROI estimado por categoria
    ROUND(SUM(lucro_total) / NULLIF(SUM(receita_total), 0) * 100, 2) AS roi_categoria_percentual
FROM classificacao_abc
GROUP BY classificacao_abc, categoria
ORDER BY 
    CASE classificacao_abc
        WHEN 'A (Top 20% produtos)' THEN 1
        WHEN 'B (Próximos 30% produtos)' THEN 2
        ELSE 3
    END,
    receita_total DESC;