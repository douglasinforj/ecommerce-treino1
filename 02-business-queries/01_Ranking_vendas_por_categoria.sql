Crie uma query que retorne o Ranking de Vendas por Categoria mostrando: Mês, Categoria, 
Total Vendas, e Percentual de contribuição para aquele mês.


WITH vendas_mensais AS (
    SELECT 
        DATE_FORMAT(p.data_pedido, '%Y-%m') AS mes,
        pr.categoria,
        SUM(ip.quantidade * ip.preco_unitario) AS total_vendas
    FROM pedidos p
    JOIN itens_pedido ip ON p.id = ip.pedido_id
    JOIN produtos pr ON pr.id = ip.produto_id
    WHERE p.status IN ('Pago', 'Entregue')
    GROUP BY mes, pr.categoria
)
SELECT 
    mes,
    categoria,
    total_vendas,
    ROUND(total_vendas / SUM(total_vendas) OVER (PARTITION BY mes) * 100, 2) AS percentual_categoria_no_mes
FROM vendas_mensais
ORDER BY mes DESC, total_vendas DESC;