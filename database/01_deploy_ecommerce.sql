-- DROP DATABASE IF EXISTS ecommerce_vendas;
-- CREATE DATABASE ecommerce_vendas;
-- USE ecommercer_vendas;

-- 1. Tabela Cliente

create table clientes (
    id INT UNSIGNED not null auto_increment,
    nome varchar(100) not null,
    email varchar(120) not null unique,
    cpf char(11) not null unique,
    data_cadastro datetime not null default current_timestamp,
    tipo_cadastro enum('PF', 'PJ') not null default 'PF',
    primary key (id),
    index idx_email (email)     --indice para buscas mais rápidas
)