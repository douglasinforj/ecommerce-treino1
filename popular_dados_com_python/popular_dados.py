import mysql.connector
from faker import Faker
import random
from datetime import datetime, timedelta
from decimal import Decimal

# Configuração
fake = Faker('pt_BR')

# Configurações do banco de dados
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'admin',
    'database': 'ecommerce_vendas'
}

# Constantes
NUM_VENDAS = 10000
DIAS_3_ANOS = 1095
DATA_INICIO = datetime.now() - timedelta(days=DIAS_3_ANOS)

# Categorias de produtos
CATEGORIAS = [
    'Eletrônicos', 'Roupas', 'Livros', 'Casa e Decoração', 
    'Esportes', 'Beleza', 'Brinquedos', 'Alimentos', 
    'Ferramentas', 'Informática'
]

# Produtos base com SKUs únicos
PRODUTOS_BASE = [
    ("Smartphone XYZ", "SMAR-001", 800.00, 1500.00, "Eletrônicos"),
    ("Notebook ABC", "NOTE-001", 2500.00, 4500.00, "Eletrônicos"),
    ("Camiseta Básica", "CAMI-001", 15.00, 49.90, "Roupas"),
    ("Calça Jeans", "CALC-001", 40.00, 129.90, "Roupas"),
    ("Livro Python", "LIVR-001", 30.00, 89.90, "Livros"),
    ("Fone Bluetooth", "FONE-001", 80.00, 199.90, "Eletrônicos"),
    ("Sofá 3 lugares", "SOFA-001", 800.00, 1500.00, "Casa e Decoração"),
    ("Bola de Futebol", "BOLA-001", 50.00, 129.90, "Esportes"),
    ("Perfume Importado", "PERF-001", 100.00, 250.00, "Beleza"),
    ("Lego Star Wars", "LEGO-001", 200.00, 399.90, "Brinquedos"),
    ("Arroz 5kg", "ARRO-001", 15.00, 29.90, "Alimentos"),
    ("Furadeira", "FURA-001", 120.00, 299.90, "Ferramentas"),
    ("Mouse Gamer", "MOUS-001", 50.00, 149.90, "Informática"),
    ("Teclado Mecânico", "TECL-001", 150.00, 350.00, "Informática"),
    ("Monitor 24''", "MONI-001", 600.00, 1200.00, "Informática")
]

def criar_conexao():
    return mysql.connector.connect(**DB_CONFIG)

def gerar_clientes(n=500):
    """Gera clientes com email e CPF/CNPJ únicos"""
    clientes = []
    emails_utilizados = set()
    cpfs_utilizados = set()
    
    for _ in range(n):
        tipo = random.choices(['PF', 'PJ'], weights=[0.9, 0.1])[0]
        
        # Gerar email único
        while True:
            email = fake.email()
            if email not in emails_utilizados:
                emails_utilizados.add(email)
                break
        
        # Gerar CPF/CNPJ único
        while True:
            if tipo == 'PF':
                cpf = fake.cpf().replace('.', '').replace('-', '')
                doc = cpf[:11]
            else:
                cnpj = fake.cnpj().replace('.', '').replace('/', '').replace('-', '')
                doc = cnpj[:14]
            
            if doc not in cpfs_utilizados:
                cpfs_utilizados.add(doc)
                break
        
        nome = fake.name() if tipo == 'PF' else fake.company()
        
        cliente = {
            'nome': nome[:100],
            'email': email,
            'cpf': doc,
            'data_cadastro': fake.date_time_between(start_date='-3y', end_date='now'),
            'tipo_cliente': tipo
        }
        clientes.append(cliente)
    
    return clientes

def gerar_produtos():
    """Gera produtos com SKU único"""
    produtos = []
    skus_utilizados = set()
    
    # Adicionar produtos base com SKUs únicos
    for nome, sku_base, preco_custo, preco_venda, categoria in PRODUTOS_BASE:
        if sku_base not in skus_utilizados:
            skus_utilizados.add(sku_base)
            produto = {
                'nome': nome,
                'sku': sku_base,
                'preco_custo': Decimal(str(preco_custo)),
                'preco_venda': Decimal(str(preco_venda)),
                'estoque_atual': random.randint(10, 500),
                'categoria': categoria
            }
            produtos.append(produto)
    
    # Gerar produtos adicionais com SKUs únicos
    contador = len(PRODUTOS_BASE)
    while len(produtos) < 100:  # Total de 100 produtos
        categoria = random.choice(CATEGORIAS)
        
        # Gerar SKU único
        while True:
            sku = f"{categoria[:4].upper()}-{contador:04d}"
            if sku not in skus_utilizados:
                skus_utilizados.add(sku)
                break
        
        preco_custo = Decimal(str(round(random.uniform(10, 1000), 2)))
        preco_venda = preco_custo * Decimal(str(round(random.uniform(1.3, 2.5), 2)))
        
        produto = {
            'nome': f"{categoria} {fake.word().capitalize()} {contador}",
            'sku': sku,
            'preco_custo': preco_custo,
            'preco_venda': preco_venda,
            'estoque_atual': random.randint(0, 1000),
            'categoria': categoria
        }
        produtos.append(produto)
        contador += 1
    
    return produtos

def gerar_pedidos_e_itens(clientes_ids, produtos_ids, num_pedidos=NUM_VENDAS):
    """Gera pedidos e itens sem duplicar produtos no mesmo pedido"""
    pedidos = []
    itens_pedido = []
    pedidos_valores = []
    
    # Dicionário para rastrear combinações pedido+produto já inseridas
    combinacoes_utilizadas = set()
    
    for i in range(num_pedidos):
        cliente_id = random.choice(clientes_ids)
        
        # Data do pedido
        data_pedido = fake.date_time_between(start_date=DATA_INICIO, end_date='now')
        
        # Status baseado na data
        dias_diferenca = (datetime.now() - data_pedido).days
        if dias_diferenca < 1:
            status = random.choices(['Aguardando', 'Pago'], weights=[0.7, 0.3])[0]
        elif dias_diferenca < 3:
            status = random.choices(['Pago', 'Enviado'], weights=[0.5, 0.5])[0]
        elif dias_diferenca < 7:
            status = random.choices(['Enviado', 'Entregue'], weights=[0.3, 0.7])[0]
        else:
            status = random.choices(['Entregue', 'Cancelado'], weights=[0.95, 0.05])[0]
        
        pedido = {
            'cliente_id': cliente_id,
            'data_pedido': data_pedido,
            'status': status,
            'valor_total': 0
        }
        pedidos.append(pedido)
        
        # Número de itens (1 a 8 itens)
        num_itens = random.choices(range(1, 9), weights=[0.3, 0.2, 0.15, 0.1, 0.08, 0.07, 0.05, 0.05])[0]
        
        # Escolher produtos únicos para este pedido
        produtos_escolhidos = []
        produtos_disponiveis = produtos_ids.copy()
        
        for _ in range(min(num_itens, len(produtos_disponiveis))):
            if not produtos_disponiveis:
                break
            produto_id = random.choice(produtos_disponiveis)
            produtos_escolhidos.append(produto_id)
            produtos_disponiveis.remove(produto_id)
        
        valor_total_pedido = 0
        
        for produto_id in produtos_escolhidos:
            quantidade = random.randint(1, 5)
            preco_unitario = Decimal(str(round(random.uniform(20, 2000), 2)))
            
            # Marcar combinação como utilizada (será validada na inserção)
            combinacao = (i, produto_id)  # i é índice temporário
            combinacoes_utilizadas.add(combinacao)
            
            item = {
                'produto_id': produto_id,
                'quantidade': quantidade,
                'preco_unitario': preco_unitario
            }
            itens_pedido.append(item)
            valor_total_pedido += preco_unitario * quantidade
        
        pedidos_valores.append(valor_total_pedido)
    
    return pedidos, itens_pedido, pedidos_valores

def gerar_pagamentos(pedidos_ids, pedidos_status, pedidos_valores, pedidos_datas):
    """Gera pagamentos sem duplicatas"""
    pagamentos = []
    
    for pedido_id, status, valor_total, data_pedido in zip(pedidos_ids, pedidos_status, pedidos_valores, pedidos_datas):
        # Só gera pagamento se não for cancelado
        if status != 'Cancelado':
            forma = random.choices(['Cartao', 'Boleto', 'Pix'], weights=[0.6, 0.2, 0.2])[0]
            
            if forma == 'Cartao':
                parcelas = random.choices([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], 
                                         weights=[0.4, 0.15, 0.1, 0.08, 0.06, 0.05, 0.04, 0.03, 0.02, 0.02, 0.01, 0.01])[0]
            else:
                parcelas = 1
            
            # Data de pagamento
            if status in ['Pago', 'Enviado', 'Entregue']:
                data_pagamento = data_pedido + timedelta(days=random.randint(0, 3))
                if data_pagamento > datetime.now():
                    data_pagamento = None
            else:
                data_pagamento = None
            
            pagamento = {
                'pedido_id': pedido_id,
                'forma_pagamento': forma,
                'parcelas': parcelas,
                'valor_pago': valor_total,
                'data_pagamento': data_pagamento
            }
            pagamentos.append(pagamento)
    
    return pagamentos

def gerar_entregas(pedidos_ids, pedidos_status, pedidos_datas):
    """Gera entregas sem duplicatas (um pedido tem uma entrega)"""
    entregas = []
    
    for pedido_id, status, data_pedido in zip(pedidos_ids, pedidos_status, pedidos_datas):
        if status in ['Enviado', 'Entregue']:
            transportadoras = ['Correios', 'JadLog', 'Loggi', 'Total Express', 'Amazon Logistics']
            
            data_envio = data_pedido + timedelta(days=random.randint(1, 3))
            if data_envio > datetime.now():
                data_envio = None
            
            if status == 'Entregue' and data_envio:
                data_entrega = data_envio + timedelta(days=random.randint(1, 10))
                if data_entrega > datetime.now():
                    data_entrega = None
            else:
                data_entrega = None
            
            entrega = {
                'pedido_id': pedido_id,
                'codigo_rastreio': fake.bothify(text='???#########??').upper(),
                'transportadora': random.choice(transportadoras),
                'data_envio': data_envio,
                'data_entrega': data_entrega
            }
            entregas.append(entrega)
    
    return entregas

def main():
    print("=== GERADOR DE DADOS FAKER (SEM DUPLICATAS) ===\n")
    
    try:
        conn = criar_conexao()
        cursor = conn.cursor()
        
        # 1. Clientes
        print("1. Gerando clientes (500) - sem duplicatas...")
        clientes = gerar_clientes(500)
        
        # Inserir clientes com tratamento de duplicatas
        for cliente in clientes:
            try:
                cursor.execute("""
                    INSERT INTO clientes (nome, email, cpf, data_cadastro, tipo_cliente)
                    VALUES (%s, %s, %s, %s, %s)
                """, (cliente['nome'], cliente['email'], cliente['cpf'], 
                      cliente['data_cadastro'], cliente['tipo_cliente']))
            except mysql.connector.IntegrityError as e:
                print(f"   ⚠️ Duplicata ignorada: {e}")
                continue
        
        conn.commit()
        
        # Buscar IDs dos clientes
        cursor.execute("SELECT id FROM clientes")
        clientes_ids = [row[0] for row in cursor.fetchall()]
        print(f"   ✅ {len(clientes_ids)} clientes inseridos")
        
        # 2. Produtos
        print("\n2. Gerando produtos (100) - sem SKUs duplicados...")
        produtos = gerar_produtos()
        
        for produto in produtos:
            try:
                cursor.execute("""
                    INSERT INTO produtos (nome, sku, preco_custo, preco_venda, estoque_atual, categoria)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (produto['nome'], produto['sku'], float(produto['preco_custo']),
                      float(produto['preco_venda']), produto['estoque_atual'], produto['categoria']))
            except mysql.connector.IntegrityError as e:
                print(f"   ⚠️ SKU duplicado ignorado: {e}")
                continue
        
        conn.commit()
        
        cursor.execute("SELECT id FROM produtos")
        produtos_ids = [row[0] for row in cursor.fetchall()]
        print(f"   ✅ {len(produtos_ids)} produtos inseridos")
        
        # 3. Pedidos
        print(f"\n3. Gerando {NUM_VENDAS} pedidos...")
        pedidos, itens_pedido, pedidos_valores = gerar_pedidos_e_itens(clientes_ids, produtos_ids)
        
        pedidos_ids = []
        pedidos_datas = []
        pedidos_status = []
        
        for i, pedido in enumerate(pedidos):
            try:
                cursor.execute("""
                    INSERT INTO pedidos (cliente_id, data_pedido, status, valor_total)
                    VALUES (%s, %s, %s, %s)
                """, (pedido['cliente_id'], pedido['data_pedido'], 
                      pedido['status'], float(pedido['valor_total'])))
                
                pedido_id = cursor.lastrowid
                pedidos_ids.append(pedido_id)
                pedidos_datas.append(pedido['data_pedido'])
                pedidos_status.append(pedido['status'])
                
                # Atualizar valor total do pedido
                if pedidos_valores[i] > 0:
                    cursor.execute("UPDATE pedidos SET valor_total = %s WHERE id = %s",
                                  (float(pedidos_valores[i]), pedido_id))
                
            except mysql.connector.Error as e:
                print(f"   ⚠️ Erro ao inserir pedido: {e}")
                continue
        
        conn.commit()
        print(f"   ✅ {len(pedidos_ids)} pedidos inseridos")
        
        # 4. Itens do Pedido (evitando PK duplicada)
        print("\n4. Inserindo itens dos pedidos...")
        itens_inseridos = 0
        combinacoes_verificadas = set()
        
        # Reconstruir os itens com os IDs reais dos pedidos
        cursor.execute("SELECT id FROM pedidos ORDER BY id")
        pedidos_ids_reais = [row[0] for row in cursor.fetchall()]
        
        for pedido_idx, pedido_id in enumerate(pedidos_ids_reais[:len(pedidos)]):
            num_itens = random.randint(1, 6)
            produtos_usados = set()
            
            for _ in range(num_itens):
                produto_id = random.choice(produtos_ids)
                
                # Evitar produto duplicado no mesmo pedido
                if produto_id in produtos_usados:
                    continue
                
                combinacao = (pedido_id, produto_id)
                
                # Evitar combinação duplicada
                if combinacao in combinacoes_verificadas:
                    continue
                
                quantidade = random.randint(1, 5)
                preco_unitario = Decimal(str(round(random.uniform(20, 2000), 2)))
                
                try:
                    cursor.execute("""
                        INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario)
                        VALUES (%s, %s, %s, %s)
                    """, (pedido_id, produto_id, quantidade, float(preco_unitario)))
                    
                    combinacoes_verificadas.add(combinacao)
                    produtos_usados.add(produto_id)
                    itens_inseridos += 1
                    
                except mysql.connector.IntegrityError:
                    # PK duplicada, ignora
                    continue
        
        conn.commit()
        print(f"   ✅ {itens_inseridos} itens inseridos")
        
        # 5. Pagamentos
        print("\n5. Gerando pagamentos...")
        pagamentos = gerar_pagamentos(pedidos_ids, pedidos_status, pedidos_valores, pedidos_datas)
        
        for pagamento in pagamentos:
            try:
                cursor.execute("""
                    INSERT INTO pagamentos (pedido_id, forma_pagamento, parcelas, valor_pago, data_pagamento)
                    VALUES (%s, %s, %s, %s, %s)
                """, (pagamento['pedido_id'], pagamento['forma_pagamento'], 
                      pagamento['parcelas'], float(pagamento['valor_pago']), 
                      pagamento['data_pagamento']))
            except mysql.connector.Error as e:
                continue
        
        conn.commit()
        print(f"   ✅ {len(pagamentos)} pagamentos inseridos")
        
        # 6. Entregas
        print("\n6. Gerando entregas...")
        entregas = gerar_entregas(pedidos_ids, pedidos_status, pedidos_datas)
        
        for entrega in entregas:
            try:
                cursor.execute("""
                    INSERT INTO entregas (pedido_id, codigo_rastreio, transportadora, data_envio, data_entrega)
                    VALUES (%s, %s, %s, %s, %s)
                """, (entrega['pedido_id'], entrega['codigo_rastreio'], 
                      entrega['transportadora'], entrega['data_envio'], 
                      entrega['data_entrega']))
            except mysql.connector.Error as e:
                continue
        
        conn.commit()
        print(f"   ✅ {len(entregas)} entregas inseridas")
        
        # Estatísticas finais
        print("\n" + "="*50)
        print("✅ DADOS GERADOS COM SUCESSO!")
        print("="*50)
        
        cursor.execute("SELECT COUNT(*) FROM clientes")
        total_clientes = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM produtos")
        total_produtos = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM pedidos")
        total_pedidos = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM itens_pedido")
        total_itens = cursor.fetchone()[0]
        
        print(f"\n📊 RESUMO FINAL:")
        print(f"   Clientes: {total_clientes}")
        print(f"   Produtos: {total_produtos}")
        print(f"   Pedidos: {total_pedidos}")
        print(f"   Itens: {total_itens}")
        
        cursor.execute("""
            SELECT 
                YEAR(data_pedido) as ano,
                COUNT(*) as total_pedidos,
                SUM(valor_total) as valor_total
            FROM pedidos 
            GROUP BY YEAR(data_pedido)
            ORDER BY ano
        """)
        
        print(f"\n📅 VENDAS POR ANO:")
        for ano, total, valor in cursor.fetchall():
            if ano:
                print(f"   {ano}: {total} pedidos - R$ {float(valor):,.2f}")
        
        conn.close()
        
    except mysql.connector.Error as err:
        print(f"❌ Erro no banco de dados: {err}")
    except Exception as e:
        print(f"❌ Erro geral: {e}")

if __name__ == "__main__":
    main()