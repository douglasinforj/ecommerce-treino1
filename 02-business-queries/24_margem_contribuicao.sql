/*

"Essa query analisa a margem de contribuição por produto, permitindo identificar quais itens geram mais lucro e 
priorizar decisões de pricing, mix de produtos e estratégias comerciais.

ROI completo
(lucro_total - custo_operacional) / investimento

Margem ponderada real (com preço histórico)
usar ip.preco_unitario em vez de p.preco_venda

*/

SELECT 
    p.id,
    p.nome,
    p.categoria,
    p.preco_venda,
    p.preco_custo,

    ROUND((p.preco_venda - p.preco_custo) / p.preco_venda * 100, 2) AS margem_percentual,

    COALESCE(SUM(CASE 
        WHEN ped.status IN ('Pago', 'Entregue') 
        THEN ip.quantidade 
    END), 0) AS unidades_vendidas,

    COALESCE(SUM(CASE 
        WHEN ped.status IN ('Pago', 'Entregue') 
        THEN ip.quantidade * (p.preco_venda - p.preco_custo)
    END), 0) AS lucro_total_bruto,

    RANK() OVER (
        ORDER BY 
        COALESCE(SUM(CASE 
            WHEN ped.status IN ('Pago', 'Entregue') 
            THEN ip.quantidade * (p.preco_venda - p.preco_custo)
        END), 0) DESC
    ) AS rank_lucro

FROM produtos p
LEFT JOIN itens_pedido ip ON p.id = ip.produto_id
LEFT JOIN pedidos ped ON ip.pedido_id = ped.id

GROUP BY p.id, p.nome, p.categoria, p.preco_venda, p.preco_custo
ORDER BY lucro_total_bruto DESC;