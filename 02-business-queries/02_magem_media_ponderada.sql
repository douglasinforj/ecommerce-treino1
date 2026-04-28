-- =====================================================
-- VERSÃO CORRIGIDA - Margem baseada em média ponderada
-- =====================================================
WITH vendas_produtos AS (
    SELECT 
        p.id,
        p.nome,
        p.categoria,
        p.preco_venda,
        p.preco_custo,
        SUM(ip.quantidade) AS unidades_vendidas,
        ROUND(SUM(ip.quantidade * ip.preco_unitario), 2) AS receita_total,
        ROUND(SUM(ip.quantidade * (ip.preco_unitario - p.preco_custo)), 2) AS lucro_total,
        -- Margem calculada pela média ponderada
        ROUND((SUM(ip.quantidade * (ip.preco_unitario - p.preco_custo)) / 
               NULLIF(SUM(ip.quantidade * ip.preco_unitario), 0)) * 100, 2) AS margem_percentual,
        COUNT(DISTINCT ip.pedido_id) AS qtd_pedidos
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
        SUM(receita_total) OVER (ORDER BY receita_total DESC) / 
        NULLIF(SUM(receita_total) OVER (), 0) AS receita_acumulada_percentual,
        CASE 
            WHEN SUM(receita_total) OVER (ORDER BY receita_total DESC) / 
                 NULLIF(SUM(receita_total) OVER (), 0) <= 0.8 THEN 'A (Alta performance)'
            WHEN SUM(receita_total) OVER (ORDER BY receita_total DESC) / 
                 NULLIF(SUM(receita_total) OVER (), 0) <= 0.95 THEN 'B (Performance média)'
            ELSE 'C (Baixa performance)'
        END AS classificacao_abc
    FROM vendas_produtos
)
SELECT 
    classificacao_abc,
    categoria,
    COUNT(*) AS qtd_produtos,
    ROUND(SUM(receita_total), 2) AS receita_total,
    ROUND(SUM(lucro_total), 2) AS lucro_total,
    ROUND(AVG(margem_percentual), 2) AS margem_media,
    CASE 
        WHEN classificacao_abc = 'A (Alta performance)' AND AVG(margem_percentual) > 40 
        THEN '🌟 Produto Estrela - Manter estoque alto'
        WHEN classificacao_abc = 'A (Alta performance)' AND AVG(margem_percentual) < 20 
        THEN '💰 Produto Volume - Otimizar custo'
        WHEN classificacao_abc = 'C (Baixa performance)' AND AVG(margem_percentual) < 10 
        THEN '⚠️ Produto Zumbi - Considerar descontinuar'
        WHEN classificacao_abc = 'C (Baixa performance)' AND AVG(margem_percentual) > 30 
        THEN '📈 Potencial de crescimento - Investir marketing'
        ELSE '🔄 Manutenção padrão'
    END AS estrategia_recomendada
FROM classificacao_abc
GROUP BY classificacao_abc, categoria
ORDER BY classificacao_abc, receita_total DESC;