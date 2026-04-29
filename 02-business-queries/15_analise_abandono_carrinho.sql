
/*
O que essa query realmente faz (tradução de negócio)

Ela responde:

“Quais clientes compraram X mas ainda não compraram Y — e quanto posso aumentar o faturamento com isso?”

Isso é:

expansão de receita
retenção ativa
personalização de oferta

*/


-- Clientes que compraram produtos da categoria X mas não compraram da categoria Y
SELECT 
    c.id,
    c.nome,
    c.email,
    GROUP_CONCAT(DISTINCT p_cat.categoria ORDER BY p_cat.categoria SEPARATOR ', ') AS categorias_compradas,
    -- Potencial de Cross-sell
    CASE 
        WHEN SUM(CASE WHEN p_cat.categoria = 'Eletronicos' THEN 1 ELSE 0 END) > 0 
         AND SUM(CASE WHEN p_cat.categoria = 'Acessorios' THEN 1 ELSE 0 END) = 0 
        THEN 'Ofertas de Acessórios'
        WHEN SUM(CASE WHEN p_cat.categoria = 'Vestuario' THEN 1 ELSE 0 END) > 0 
         AND SUM(CASE WHEN p_cat.categoria = 'Calcados' THEN 1 ELSE 0 END) = 0 
        THEN 'Ofertas de Calçados'
        ELSE 'Mix Completo'
    END AS oportunidade_cross_sell
FROM clientes c
JOIN pedidos p ON c.id = p.cliente_id
JOIN itens_pedido ip ON p.id = ip.pedido_id
JOIN produtos p_cat ON ip.produto_id = p_cat.id
WHERE p.status IN ('Pago', 'Entregue')
GROUP BY c.id, c.nome, c.email
HAVING oportunidade_cross_sell != 'Mix Completo'
LIMIT 50;