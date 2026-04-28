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
)


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
)





--Comandos de Verificação
select * from clientes;
select * from produtos;