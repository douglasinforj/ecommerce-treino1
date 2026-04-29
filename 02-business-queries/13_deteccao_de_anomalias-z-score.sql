-- Identificar dias atípicos de venda
WITH stats_diarios AS (
    SELECT 
        DATE(data_pedido) AS dia,
        SUM(valor_total) AS receita_dia,
        AVG(SUM(valor_total)) OVER () AS media_geral,
        STDDEV(SUM(valor_total)) OVER () AS desvio_padrao
    FROM pedidos
    WHERE data_pedido >= DATE_SUB(NOW(), INTERVAL 90 DAY)
      AND status NOT IN ('Cancelado')
    GROUP BY DATE(data_pedido)
)
SELECT 
    dia,
    receita_dia,
    media_geral,
    desvio_padrao,
    (receita_dia - media_geral) / desvio_padrao AS z_score,
    CASE 
        WHEN ABS((receita_dia - media_geral) / desvio_padrao) > 2 THEN 'ANOMALIA DETECTADA'
        WHEN ABS((receita_dia - media_geral) / desvio_padrao) > 1 THEN 'Variação Significativa'
        ELSE 'Normal'
    END AS alerta
FROM stats_diarios
ORDER BY z_score DESC;