
-- 1 - CAMADA BASE (INDEX) MELHORANDO A CONSULTA

CREATE INDEX idx_itens_pedido_pedido ON itens_pedido(pedido_id);
CREATE INDEX idx_itens_pedido_produto ON itens_pedido(produto_id);
CREATE INDEX idx_pedidos_status_data ON pedidos(status, data_pedido);

-- 2 - TABELA DE RECOMENDAÇÕES

CREATE TABLE recomendacoes_produto (
    produto_base_id INT UNSIGNED NOT NULL,
    produto_recomendado_id INT UNSIGNED NOT NULL,
    suporte INT NOT NULL,
    confianca DECIMAL(8,4),
    lift DECIMAL(8,4),
    data_calculo DATETIME,
    PRIMARY KEY (produto_base_id, produto_recomendado_id),
    INDEX idx_base (produto_base_id),
    INDEX idx_recomendado (produto_recomendado_id)
);

-- 3 - LIMPAR PARA RECALCULAR MANUAMENTE CASO SEJA NECESSÁRIO MAS AUTOMATIZAREMOS A SEGUIR
TRUNCATE TABLE recomendacoes_produto;




-- 4 - GERAR RECOMENDAÇÕES (PERFORMATICO)


INSERT INTO recomendacoes_produto
SELECT 
    p1.id AS produto_base,
    p2.id AS produto_recomendado,

    COUNT(DISTINCT ip1.pedido_id) AS suporte,

    -- Confiança
    ROUND(
        COUNT(DISTINCT ip1.pedido_id) * 1.0 /
        (
            SELECT COUNT(DISTINCT pedido_id) 
            FROM itens_pedido 
            WHERE produto_id = p1.id
        ),
    4) AS confianca,

    -- Lift
    ROUND(
        (
            COUNT(DISTINCT ip1.pedido_id) * 1.0 /
            (SELECT COUNT(DISTINCT id) FROM pedidos)
        )
        /
        (
            (
                SELECT COUNT(DISTINCT pedido_id) 
                FROM itens_pedido 
                WHERE produto_id = p1.id
            ) * 1.0 /
            (SELECT COUNT(DISTINCT id) FROM pedidos)
        )
        /
        (
            (
                SELECT COUNT(DISTINCT pedido_id) 
                FROM itens_pedido 
                WHERE produto_id = p2.id
            ) * 1.0 /
            (SELECT COUNT(DISTINCT id) FROM pedidos)
        )
    , 4) AS lift,

    NOW()

FROM itens_pedido ip1
JOIN itens_pedido ip2 
    ON ip1.pedido_id = ip2.pedido_id 
   AND ip1.produto_id < ip2.produto_id

JOIN produtos p1 ON ip1.produto_id = p1.id
JOIN produtos p2 ON ip2.produto_id = p2.id
JOIN pedidos ped ON ip1.pedido_id = ped.id

WHERE ped.status IN ('Pago', 'Entregue')

GROUP BY p1.id, p2.id
HAVING suporte >= 3;

-- Test de gravação de dados na tabela
SELECT * from recomendacoes_produto;


-- 5 - CAMADA DE CONSUMO SQL PURO CONSULTA CLIENTE (FAREMOS A VERSÃO PARA APLICAÇÃO)


-- Pode recomendar produtos que o cliente já comprou (Ruim), esta ajustada para ão acontecer isso
SELECT 
    c.id AS cliente_id,
    p.nome AS produto_recomendado,
    MAX(rp.confianca) AS confianca,
    MAX(rp.lift) AS lift
FROM clientes c

JOIN pedidos ped ON ped.cliente_id = c.id
JOIN itens_pedido ip ON ip.pedido_id = ped.id

JOIN recomendacoes_produto rp 
    ON rp.produto_base_id = ip.produto_id

JOIN produtos p 
    ON p.id = rp.produto_recomendado_id

WHERE ped.status IN ('Pago', 'Entregue')
  AND c.id = 1

  -- NÃO recomendar o que já comprou
  AND p.id NOT IN (
      SELECT ip2.produto_id
      FROM pedidos ped2
      JOIN itens_pedido ip2 ON ip2.pedido_id = ped2.id
      WHERE ped2.cliente_id = c.id
  )

GROUP BY c.id, p.id, p.nome
ORDER BY lift DESC, confianca DESC
LIMIT 10;


-- 6 - SEGMENTAÇÃO DE CLIENTES, COMPLEMENTO ESTRATÉGICO VIP ou Fiel


SELECT 
    c.id,
    COUNT(DISTINCT p.id) AS total_pedidos,
    SUM(p.valor_total) AS faturamento,
    AVG(p.valor_total) AS ticket_medio,
    
    CASE 
        WHEN SUM(p.valor_total) > 10000 THEN 'VIP'
        WHEN SUM(p.valor_total) > 3000 THEN 'Fiel'
        ELSE 'Ocasional'
    END AS segmento

FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
WHERE p.status IN ('Pago', 'Entregue')
GROUP BY c.id;



-- 7 - AUTOMAÇÂO COM EVENT
-- OBS.: Muitos times em produção preferem usar cron(Linux), backend scheduler (Spring / Django), AirFlow  para mais controle e observabilidade

DELIMITER $$

CREATE EVENT gerar_recomendacoes_diarias
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    TRUNCATE TABLE recomendacoes_produto;

    INSERT INTO recomendacoes_produto
    
        SELECT 
        p1.id AS produto_base,
        p2.id AS produto_recomendado,

        COUNT(DISTINCT ip1.pedido_id) AS suporte,

        -- Confiança
        ROUND(
            COUNT(DISTINCT ip1.pedido_id) * 1.0 /
            (
                SELECT COUNT(DISTINCT pedido_id) 
                FROM itens_pedido 
                WHERE produto_id = p1.id
            ),
        4) AS confianca,

        -- Lift
        ROUND(
            (
                COUNT(DISTINCT ip1.pedido_id) * 1.0 /
                (SELECT COUNT(DISTINCT id) FROM pedidos)
            )
            /
            (
                (
                    SELECT COUNT(DISTINCT pedido_id) 
                    FROM itens_pedido 
                    WHERE produto_id = p1.id
                ) * 1.0 /
                (SELECT COUNT(DISTINCT id) FROM pedidos)
            )
            /
            (
                (
                    SELECT COUNT(DISTINCT pedido_id) 
                    FROM itens_pedido 
                    WHERE produto_id = p2.id
                ) * 1.0 /
                (SELECT COUNT(DISTINCT id) FROM pedidos)
            )
        , 4) AS lift,

        NOW()

    FROM itens_pedido ip1
    JOIN itens_pedido ip2 
        ON ip1.pedido_id = ip2.pedido_id 
    AND ip1.produto_id < ip2.produto_id

    JOIN produtos p1 ON ip1.produto_id = p1.id
    JOIN produtos p2 ON ip2.produto_id = p2.id
    JOIN pedidos ped ON ip1.pedido_id = ped.id

    WHERE ped.status IN ('Pago', 'Entregue')

    GROUP BY p1.id, p2.id
    HAVING suporte >= 3;        
    
END;

DELIMITER ;

-- VERIFICAÇÕES EVENT---
-- Lista eventos do banco
SHOW EVENTS;
-- Ver especifico
SHOW EVENTS LIKE 'gerar_recomendacoes_diarias';
-- Ver detalhes completos
SHOW CREATE EVENT gerar_recomendacoes_diarias;
-- Teste com menos tempo ao inves de espera 1 dia
ON SCHEDULE EVERY 1 MINUTE


-- 8 - VIEW DE RECOMENDACOES PRONTA PARA CONSUMO


CREATE VIEW vw_recomendacoes_cliente AS
SELECT 
    ped.cliente_id,
    rp.produto_base_id,
    rp.produto_recomendado_id,
    p.nome AS produto_recomendado,
    rp.confianca,
    rp.lift
FROM pedidos ped
JOIN itens_pedido ip ON ip.pedido_id = ped.id
JOIN recomendacoes_produto rp 
    ON rp.produto_base_id = ip.produto_id
JOIN produtos p 
    ON p.id = rp.produto_recomendado_id
WHERE ped.status IN ('Pago', 'Entregue');

-- 9 - EXEMPLO PRÁTICO E SIMPLES DE CONSUMO DA VIEW RECOMENDACOES

SELECT *
FROM vw_recomendacoes_cliente
WHERE cliente_id = 1
ORDER BY lift DESC
LIMIT 10;