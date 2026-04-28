# Projeto banco de dados E-commerce
Projeto criado do zero com a finalidade de repassar conhecimentos adquiridos pela carreira de Analista de Suporte, hoje pratico
com foco de ser um desenvolvedor de Sistema, onde SQL é muito exigido pelo mercado.

# Diagrama Lógico

 - clientes (PK:id)
 - produtos (PK:id)
 - pedidos (PK:id, FK:cliente_id)
 - itens_pedido (PK Composta: pedido_id + produto_id, FK: ambos)
 - pagamentos (PK:id, FK:pedido_id) - One-to-One ou One-to-Many
 - entregas (PK: id, FK: pedido_id)


# Populando dados com python com Faker
- Criar uma pasta 'popular_dados_com_python'
- Criar ambiente virtual  - No prompt: python -m venv venv
- ativar ambiente virtual - Acessar pasta: popular_dados_com_python\venv\Scripts   rodar: .\activate
- instalar dependecias: pip install faker mysql-connector-python pandas