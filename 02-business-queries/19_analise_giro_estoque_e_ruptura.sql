
-- ANÁLISE DE ESTOQUE E SUPPLY CHAIN - Giro de Estoque e Produtos Zumbis
/*
"Essa query é uma análise de performance de estoque, focada em giro, cobertura e 
identificação de riscos operacionais como ruptura e excesso, auxiliando decisões de 
reposição e redução de capital parado."

- Análise de giro de estoque e cobertura
  - Total vendido por produto
  - Giro de estoque
  - Dias para zerar estoque
  - Alertas operacionais (excesso, ruptura, produtos sem venda)

*/

WITH vendas_produto AS (
    SELECT 
        produto_id,
        SUM(quantidade) AS total_vendido,
        COUNT(DISTINCT pedido_id) AS vezes_vendido,
        DATEDIFF(MAX(p.data_pedido), MIN(p.data_pedido)) AS dias_ativo
    FROM itens_pedido ip
    JOIN pedidos p ON ip.pedido_id = p.id
    WHERE p.status IN ('Pago', 'Entregue')
    GROUP BY produto_id
)
SELECT 
    p.id,
    p.nome,
    p.categoria,
    p.estoque_atual,
    COALESCE(vp.total_vendido, 0) AS total_vendido,
    COALESCE(vp.vezes_vendido, 0) AS vezes_vendido,
    -- Giro de estoque = vendido / estoque médio (usamos estoque atual como proxy)
    ROUND(COALESCE(vp.total_vendido, 0) / NULLIF(p.estoque_atual, 0), 2) AS giro_estoque,
    -- Dias para zerar estoque
    ROUND(p.estoque_atual / NULLIF((COALESCE(vp.total_vendido, 0) / NULLIF(vp.dias_ativo, 0)), 0), 0) AS dias_para_zerar,
    -- Classificação ABC (80/20)
    CASE 
        WHEN COALESCE(vp.total_vendido, 0) = 0 THEN 'Zumbi (Sem venda)'
        WHEN p.estoque_atual > 100 AND COALESCE(vp.total_vendido, 0) < 10 THEN 'Excesso de Estoque'
        WHEN p.estoque_atual < 10 AND COALESCE(vp.total_vendido, 0) > 50 THEN 'Ruptura Iminente'
        ELSE 'Normal'
    END AS alerta_estoque
FROM produtos p
LEFT JOIN vendas_produto vp ON p.id = vp.produto_id
ORDER BY giro_estoque ASC, p.estoque_atual DESC;