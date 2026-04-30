/*
ANÁLISE DE SAZONALIDADE E TENDÊNCIAS
Vendas por Hora/Dia/Semana (Otimização de Marketing)
*/



WITH base AS (
    SELECT 
        DATE(data_pedido) AS dia,
        DAYOFWEEK(data_pedido) AS dia_semana_num,
        CASE DAYOFWEEK(data_pedido)
            WHEN 1 THEN 'Domingo'
            WHEN 2 THEN 'Segunda'
            WHEN 3 THEN 'Terça'
            WHEN 4 THEN 'Quarta'
            WHEN 5 THEN 'Quinta'
            WHEN 6 THEN 'Sexta'
            WHEN 7 THEN 'Sábado'
        END AS dia_semana,
        HOUR(data_pedido) AS hora_dia,

        COUNT(*) AS total_pedidos,
        SUM(valor_total) AS valor_total,
        AVG(valor_total) AS ticket_medio

    FROM pedidos
    WHERE data_pedido >= DATE_SUB(NOW(), INTERVAL 180 DAY)
      AND status NOT IN ('Cancelado')

    GROUP BY dia, dia_semana_num, dia_semana, hora_dia
)

SELECT 
    *,
    ROUND(
        AVG(total_pedidos) OVER (
            ORDER BY dia 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ), 1
    ) AS media_movel_30dias

FROM base
ORDER BY dia_semana_num, hora_dia;