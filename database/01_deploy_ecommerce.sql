-- DROP DATABASE IF EXISTS ecommerce_vendas;
-- CREATE DATABASE ecommerce_vendas;
USE ecommerce_vendas;

-- 1. Tabela Cliente

create table clientes (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email varchar(120) not null unique,
    cpf char(11) not null unique,
    data_cadastro datetime not null default current_timestamp,
    tipo_cadastro enum('PF', 'PJ') not null default 'PF',
    primary key (id),
    index idx_email (email)     
);


-- 2. Tabela Produtos
create table produtos (
    id int UNSIGNED not null AUTO_INCREMENT,
    nome varchar(200) not null,
    sku varchar(50) not null unique,
    preco_custo decimal(10,2),
    preco_venda decimal(10,2),
    estoque_atual int not null default 0,
    categoria varchar(50),
    primary key (id),
    index idx_categoria (categoria)
);


-- 3. Tabela Pedidos  (Cabeçalho)
CREATE TABLE pedidos (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cliente_id INT UNSIGNED NOT NULL,
    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Aguardando', 'Pago', 'Enviado', 'Entregue', 'Cancelado') DEFAULT 'Aguardando',
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (id),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT,
    INDEX idx_status (status),
    INDEX idx_data (data_pedido)
);


-- 4. Tabela Itens do Pedido (Granularidade)
CREATE TABLE itens_pedido (
    pedido_id INT UNSIGNED NOT NULL,
    produto_id INT UNSIGNED NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL, -- Preço na hora da compra (histórico)
    PRIMARY KEY (pedido_id, produto_id),
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE RESTRICT
);






--Comandos de Verificação
select * from clientes;
select * from produtos;
select * from pedidos;
select * from itens_pedido;