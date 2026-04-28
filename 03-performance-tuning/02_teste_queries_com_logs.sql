--Apara ambientes de estudos em LAB

-- Se não ativado
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 2; -- Queries acima de 2 segundos


-- 1. Criar uma tabela específica para log de consultas
CREATE TABLE meu_log_consultas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    query_text TEXT,
    query_time DECIMAL(10,6)
);

-- 2. Criar procedure para registrar consultas manuais
DELIMITER $$
CREATE PROCEDURE log_query(IN sql_query TEXT, IN tempo DECIMAL(10,6))
BEGIN
    INSERT INTO meu_log_consultas (query_text, query_time) 
    VALUES (sql_query, tempo);
END$$
DELIMITER ;

-- 3. Usar nos testes
SET @start = NOW(6);
SELECT * FROM produtos WHERE nome LIKE '%smartphone%';
SET @end = NOW(6);
CALL log_query('SELECT * FROM produtos WHERE nome LIKE ''%smartphone%''', 
               TIMESTAMPDIFF(MICROSECOND, @start, @end) / 1000000);