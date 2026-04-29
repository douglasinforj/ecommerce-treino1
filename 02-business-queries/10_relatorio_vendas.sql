
--Relatório de Vendas Completo
-- 3 tabelas

--EXPLAIN 
SELECT 
    c.nome,
    c.email,
    p.data_pedido,
    p.valor_total,
    pg.forma_pagamento,
    pr.nome as produto_nome,
    ip.quantidade
FROM pedidos p
JOIN clientes c ON c.id = p.cliente_id
JOIN pagamentos pg ON pg.pedido_id = p.id
JOIN itens_pedido ip ON ip.pedido_id = p.id
JOIN produtos pr ON pr.id = ip.produto_id
WHERE p.data_pedido BETWEEN '2024-01-01' AND '2024-12-31'
  AND p.status IN ('Pago', 'Entregue');


  -- Forçar ordem de JOIN (MySQL pode escolher ordem errada)
-- EXPLAIN 
SELECT STRAIGHT_JOIN  -- Força ordem de JOIN como escrita
    c.nome,
    c.email,
    p.data_pedido,
    p.valor_total,
    pg.forma_pagamento,
    pr.nome as produto_nome,
    ip.quantidade
FROM pedidos p
JOIN clientes c ON c.id = p.cliente_id
JOIN pagamentos pg ON pg.pedido_id = p.id
JOIN itens_pedido ip ON ip.pedido_id = p.id
JOIN produtos pr ON pr.id = ip.produto_id
WHERE p.data_pedido BETWEEN '2024-01-01' AND '2024-12-31'
  AND p.status IN ('Pago', 'Entregue');