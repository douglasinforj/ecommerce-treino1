
/*
 Comparativo Ano vs Ano (YoY)
*/

WITH vendas_ano_atual AS (
    SELECT 
        MONTH(data_pedido) AS mes,
        YEAR(data_pedido) AS ano,
        COUNT(*) AS qtd_pedidos,
        SUM(valor_total) AS receita
    FROM pedidos
    WHERE YEAR(data_pedido) = YEAR(NOW())
      AND status NOT IN ('Cancelado')
    GROUP BY mes, ano
),
vendas_ano_anterior AS (
    SELECT 
        MONTH(data_pedido) AS mes,
        YEAR(data_pedido) AS ano,
        COUNT(*) AS qtd_pedidos_ant,
        SUM(valor_total) AS receita_ant
    FROM pedidos
    WHERE YEAR(data_pedido) = YEAR(NOW()) - 1
      AND status NOT IN ('Cancelado')
    GROUP BY mes, ano
)
SELECT 
    va.mes,
    va.receita AS receita_atual,
    van.receita_ant AS receita_ano_passado,
    ROUND(((va.receita - van.receita_ant) / van.receita_ant) * 100, 2) AS crescimento_ytd,
    va.qtd_pedidos AS pedidos_atual,
    van.qtd_pedidos_ant AS pedidos_passado,
    ROUND(((va.qtd_pedidos - van.qtd_pedidos_ant) / van.qtd_pedidos_ant) * 100, 2) AS crescimento_pedidos
FROM vendas_ano_atual va
LEFT JOIN vendas_ano_anterior van ON va.mes = van.mes
ORDER BY va.mes;