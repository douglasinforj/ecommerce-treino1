--1. Ver processos rodando agora
SHOW full processlist;

--2. Ligar o log de queries lentas (identificar o problemas)
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 2;

-- 3. Analisar uma query específica com EXPLAIN (matada)
EXPLAIN SELECT c.nome, SUM(p.valor_total) 
FROM pedidos p
JOIN clientes c ON c.id = p.cliente_id
WHERE p.data_pedido > '2024-01-01'
GROUP BY c.id;
-- SE aparecer "Using temporary; Using filesort" -> RUIM. Se "Using index" -> ÓTIMO.


-- 4. Ver índices não utilizados (performance tuning avançado)
SELECT * FROM sys.schema_unused_indexes;


