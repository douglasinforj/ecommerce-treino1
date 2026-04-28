# Projeto banco de dados E-commerce
Projeto criado do zero com a finalidade de repassar conhecimentos adquiridos pela carreira de Analista de Suporte, hoje pratico
com foco de ser um desenvolvedor de Sistema, onde SQL é muito exigido pelo mercado.

## Diagrama Lógico

 - clientes (PK:id)
 - produtos (PK:id)
 - pedidos (PK:id, FK:cliente_id)
 - itens_pedido (PK Composta: pedido_id + produto_id, FK: ambos)
 - pagamentos (PK:id, FK:pedido_id) - One-to-One ou One-to-Many
 - entregas (PK: id, FK: pedido_id)

![Diagrama](./images/diagrama.png)

## Criando Banco de dados e tabelas
 - [script banco de dados e tabelas](./01-database-schema/01_deploy_ecommerce.sql)


## Populando dados com python com Faker
- Criar uma pasta 'popular_dados_com_python'
- Criar ambiente virtual  - No prompt: python -m venv venv
- ativar ambiente virtual - Acessar pasta: popular_dados_com_python\venv\Scripts   rodar: .\activate
- instalar dependecias: pip install faker mysql-connector-python pandas
## Link
- [popular_dados.py](./popular_dados_com_python/popular_dados.py)

## CHECKLIST DO DBA: EXPLAIN
Interpretações de Explain e dicas do que fazer:
### EXPLAIN	 | Interpretação | O que fazer
'''
 type = ALL	           |Full table scan	        | Adicionar índice na coluna do WHERE/JOIN
|------------------------------------------------------------------------------------
| type = index	           | Full index scan	    | Índice muito largo ou query mal escrita
| type = range	           | Busca por intervalo	| Bom! Otimizar com índice correto
| type = ref	           | Busca por igualdade	| Ótimo! Índice funcionando
| type = const	           | Única linha (PK)	    | Perfeito!
| Extra = Using temporary  | Tabela temporária	    | Otimizar GROUP BY/DISTINCT/ORDER BY
| Extra = Using filesort   | Ordenação externa	    | Adicionar índice na coluna ORDER BY
| Extra = Using index	   | Index covering	        | Perfeito! Dados vem só do índice
| Extra = Using where	   | Filtro pós-índice      | Normal, mas tenta cobrir tudo com índice
| key_len muito alto	   | Índice largo demais	| Revisar colunas no índice composto
| rows estimado	           | Linhas escaneadas	    | Quanto menor, melhor (<1000 é ideal)
| filtered = 100%	       | Filtro eficiente	    | Quanto maior, melhor
'''