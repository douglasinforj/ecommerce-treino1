/*
Curva ABC REAL (80/20 baseada em faturamento)

Aqui não é regra fixa — é percentual acumulado

Conceitos:

A classificação ABC na curva é uma metodologia de gestão que prioriza itens de estoque com base na sua importância financeira (faturamento ou valor de consumo). Geralmente, segue a regra 80/20: a classe A representa cerca de 20% dos itens (80% do valor), B representa 30% dos itens (15% do valor) e C os 50% restantes (5% do valor). 

Detalhamento da Classificação ABC:
Classe A (Alta Relevância): São os produtos mais importantes, representando cerca de 80% do faturamento, 
mas em pequena quantidade de itens (aprox. 20%). Exigem controle rigoroso, inventários frequentes e negociação próxima com fornecedores. 

Classe B (Relevância Média): Produtos intermediários, compondo cerca de 15% do faturamento e 30% dos itens. O controle é moderado, 
visando um equilíbrio entre estoque e custo. 

Classe C (Baixa Relevância): Itens com baixo faturamento (cerca de 5%), mas que representam a maior quantidade física de produtos (aprox. 50%). 
Exigem menos controle, evitando altos custos de armazenagem

*/
WITH faturamento_produto AS (
    SELECT 
        p.id,
        p.nome,
        SUM(ip.quantidade * ip.preco_unitario) AS faturamento
    FROM produtos p
    JOIN itens_pedido ip ON ip.produto_id = p.id
    JOIN pedidos ped ON ped.id = ip.pedido_id
    WHERE ped.status IN ('Pago', 'Entregue')
    GROUP BY p.id, p.nome
),

ranking AS (
    SELECT *,
        SUM(faturamento) OVER () AS total_geral,
        SUM(faturamento) OVER (ORDER BY faturamento DESC) AS acumulado
    FROM faturamento_produto
)

SELECT 
    id,
    nome,
    faturamento,
    ROUND((faturamento / total_geral) * 100, 2) AS percentual,
    ROUND((acumulado / total_geral) * 100, 2) AS percentual_acumulado,

    CASE 
        WHEN (acumulado / total_geral) <= 0.80 THEN 'A'
        WHEN (acumulado / total_geral) <= 0.95 THEN 'B'
        ELSE 'C'
    END AS classificacao_abc

FROM ranking
ORDER BY faturamento DESC;