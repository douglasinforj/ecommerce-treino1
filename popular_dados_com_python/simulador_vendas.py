import mysql.connector
from faker import Faker
import random
from datetime import datetime, timedelta
from decimal import Decimal
import time
import argparse
from threading import Lock

# Configuração
fake = Faker('pt_BR')

# Configurações do banco de dados
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'admin',
    'database': 'ecommerce_vendas'
}

# Períodos do dia com diferentes intensidades de venda
PERIODOS_VENDA = [
    {'nome': 'Madrugada', 'hora_inicio': 0, 'hora_fim': 6, 'fator': 0.1, 'intervalo_segundos': 300},
    {'nome': 'Manhã', 'hora_inicio': 6, 'hora_fim': 12, 'fator': 0.8, 'intervalo_segundos': 45},
    {'nome': 'Tarde', 'hora_inicio': 12, 'hora_fim': 18, 'fator': 1.2, 'intervalo_segundos': 30},
    {'nome': 'Noite', 'hora_inicio': 18, 'hora_fim': 24, 'fator': 1.5, 'intervalo_segundos': 20}
]

class SimuladorVendasTempoReal:
    def __init__(self):
        self.running = True
        self.lock = Lock()
        self.clientes_cache = []
        self.produtos_cache = []
        self.vendas_dia_atual = 0
        self.valor_total_dia = 0.0  # Usando float para facilitar
        self.carregar_caches()
        
    def carregar_caches(self):
        """Carrega clientes e produtos existentes do banco"""
        try:
            conn = mysql.connector.connect(**DB_CONFIG)
            cursor = conn.cursor(dictionary=True)
            
            cursor.execute("SELECT id, tipo_cliente FROM clientes")
            self.clientes_cache = cursor.fetchall()
            
            cursor.execute("SELECT id, sku, preco_venda, estoque_atual FROM produtos")
            self.produtos_cache = cursor.fetchall()
            
            # Converter Decimal para float para facilitar operações
            for produto in self.produtos_cache:
                if isinstance(produto['preco_venda'], Decimal):
                    produto['preco_venda'] = float(produto['preco_venda'])
                if isinstance(produto['estoque_atual'], Decimal):
                    produto['estoque_atual'] = int(produto['estoque_atual'])
            
            cursor.close()
            conn.close()
            
            print(f"✅ Cache carregado: {len(self.clientes_cache)} clientes, {len(self.produtos_cache)} produtos")
        except Exception as e:
            print(f"❌ Erro ao carregar cache: {e}")
    
    def atualizar_cache_produtos(self):
        """Atualiza o cache de produtos periodicamente"""
        try:
            conn = mysql.connector.connect(**DB_CONFIG)
            cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT id, sku, preco_venda, estoque_atual FROM produtos")
            self.produtos_cache = cursor.fetchall()
            for produto in self.produtos_cache:
                if isinstance(produto['preco_venda'], Decimal):
                    produto['preco_venda'] = float(produto['preco_venda'])
                if isinstance(produto['estoque_atual'], Decimal):
                    produto['estoque_atual'] = int(produto['estoque_atual'])
            cursor.close()
            conn.close()
        except Exception as e:
            print(f"⚠️ Erro ao atualizar cache: {e}")
    
    def gerar_novo_cliente(self):
        """Gera um novo cliente"""
        tipo = random.choices(['PF', 'PJ'], weights=[0.95, 0.05])[0]
        
        if tipo == 'PF':
            nome = fake.name()
            cpf = fake.cpf().replace('.', '').replace('-', '')
            doc = cpf[:11]
        else:
            nome = fake.company()
            cnpj = fake.cnpj().replace('.', '').replace('/', '').replace('-', '')
            doc = cnpj[:14]
        
        cliente = {
            'nome': nome[:100],
            'email': fake.email(),
            'cpf': doc,
            'data_cadastro': datetime.now(),
            'tipo_cliente': tipo
        }
        
        try:
            conn = mysql.connector.connect(**DB_CONFIG)
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO clientes (nome, email, cpf, data_cadastro, tipo_cliente)
                VALUES (%s, %s, %s, %s, %s)
            """, (cliente['nome'], cliente['email'], cliente['cpf'], 
                  cliente['data_cadastro'], cliente['tipo_cliente']))
            conn.commit()
            cliente_id = cursor.lastrowid
            cursor.close()
            conn.close()
            
            # Atualizar cache
            with self.lock:
                self.clientes_cache.append({'id': cliente_id, 'tipo_cliente': cliente['tipo_cliente']})
            
            print(f"   ✨ Novo cliente cadastrado: {cliente['nome']} (ID: {cliente_id})")
            return cliente_id
        except Exception as e:
            print(f"   ⚠️ Erro ao criar cliente: {e}")
            return random.choice(self.clientes_cache)['id'] if self.clientes_cache else None
    
    def obter_cliente(self):
        """Obtém um cliente (existente ou novo)"""
        # 15% de chance de ser novo cliente (crescimento orgânico)
        if not self.clientes_cache or random.random() < 0.15:
            return self.gerar_novo_cliente()
        return random.choice(self.clientes_cache)['id']
    
    def processar_pedido(self, cliente_id, data_pedido):
        """Processa um único pedido em tempo real"""
        try:
            conn = mysql.connector.connect(**DB_CONFIG)
            cursor = conn.cursor()
            
            # Status baseado no tempo (vendas de hoje começam como Pendentes)
            horas_desde_pedido = (datetime.now() - data_pedido).total_seconds() / 3600
            
            if horas_desde_pedido < 1:
                status = random.choices(['Aguardando', 'Pago'], weights=[0.6, 0.4])[0]
            elif horas_desde_pedido < 6:
                status = random.choices(['Pago', 'Processando'], weights=[0.7, 0.3])[0]
            else:
                status = random.choices(['Pago', 'Enviado', 'Entregue'], weights=[0.3, 0.5, 0.2])[0]
            
            # Criar pedido
            cursor.execute("""
                INSERT INTO pedidos (cliente_id, data_pedido, status, valor_total)
                VALUES (%s, %s, %s, %s)
            """, (cliente_id, data_pedido, status, 0.0))
            
            pedido_id = cursor.lastrowid
            
            # Número de itens (1 a 5 itens, mais realista para dia a dia)
            num_itens = random.choices([1, 2, 3, 4, 5], weights=[0.4, 0.3, 0.15, 0.1, 0.05])[0]
            
            # Escolher produtos aleatórios (sem repetir no mesmo pedido)
            produtos_disponiveis = self.produtos_cache.copy()
            produtos_escolhidos = random.sample(produtos_disponiveis, min(num_itens, len(produtos_disponiveis)))
            valor_total = 0.0
            
            for produto in produtos_escolhidos:
                quantidade = random.randint(1, 3)  # Quantidades menores para realismo
                valor_total += produto['preco_venda'] * quantidade
                
                # Verificar e atualizar estoque
                with self.lock:
                    if produto['estoque_atual'] >= quantidade:
                        novo_estoque = produto['estoque_atual'] - quantidade
                        cursor.execute("""
                            UPDATE produtos SET estoque_atual = %s WHERE id = %s
                        """, (novo_estoque, produto['id']))
                        produto['estoque_atual'] = novo_estoque
                
                cursor.execute("""
                    INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario)
                    VALUES (%s, %s, %s, %s)
                """, (pedido_id, produto['id'], quantidade, produto['preco_venda']))
            
            # Atualizar valor total do pedido
            cursor.execute("UPDATE pedidos SET valor_total = %s WHERE id = %s", (valor_total, pedido_id))
            
            # Processar pagamento (90% dos pedidos são pagos)
            if random.random() < 0.9:
                forma = random.choices(['Cartao', 'Pix', 'Boleto'], weights=[0.6, 0.3, 0.1])[0]
                parcelas = random.choice([1, 2, 3]) if forma == 'Cartao' else 1
                
                # Pagamento pode ser imediato ou demorar alguns minutos
                minutos_ate_pagamento = random.randint(0, 30)
                data_pagamento = data_pedido + timedelta(minutes=minutos_ate_pagamento)
                
                cursor.execute("""
                    INSERT INTO pagamentos (pedido_id, forma_pagamento, parcelas, valor_pago, data_pagamento)
                    VALUES (%s, %s, %s, %s, %s)
                """, (pedido_id, forma, parcelas, valor_total, data_pagamento))
            
            # Processar entrega (apenas para pedidos pagos com mais de 2 horas)
            if horas_desde_pedido > 2 and status in ['Pago', 'Enviado', 'Entregue']:
                transportadoras = ['Correios', 'JadLog', 'Loggi', 'Total Express']
                
                # Data de envio pode ser hoje ou amanhã
                dias_para_envio = 0 if random.random() < 0.7 else 1
                data_envio = data_pedido + timedelta(days=dias_para_envio, hours=random.randint(1, 8))
                
                if data_envio <= datetime.now():
                    status_entrega = random.choices(['Preparando', 'Enviado', 'Em_transito'], weights=[0.3, 0.5, 0.2])[0]
                    data_entrega = None
                else:
                    status_entrega = 'Pendente'
                    data_entrega = None
                
                cursor.execute("""
                    INSERT INTO entregas (pedido_id, codigo_rastreio, transportadora, 
                        data_envio, data_entrega, status, data_previsao_entrega, atualizado_por)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (pedido_id, fake.bothify(text='???#########??').upper(), random.choice(transportadoras),
                      data_envio if data_envio <= datetime.now() else None, 
                      data_entrega, status_entrega,
                      data_envio + timedelta(days=random.randint(3, 10)) if data_envio else None,
                      'Sistema'))
            
            conn.commit()
            cursor.close()
            conn.close()
            
            return pedido_id, valor_total
            
        except Exception as e:
            print(f"   ❌ Erro ao processar pedido: {e}")
            return None, 0.0
    
    def get_periodo_atual(self):
        """Retorna o período atual baseado na hora"""
        hora_atual = datetime.now().hour
        for periodo in PERIODOS_VENDA:
            if periodo['hora_inicio'] <= hora_atual < periodo['hora_fim']:
                return periodo
        return PERIODOS_VENDA[2]  # Padrão: tarde
    
    def should_generate_venda(self):
        """Decide se deve gerar uma venda agora baseado no período"""
        periodo = self.get_periodo_atual()
        
        # Probabilidade baseada no fator do período (quanto maior o fator, mais vendas)
        prob_base = 0.3  # 30% de chance base
        prob_atual = prob_base * periodo['fator']
        
        # Ajustar para horários de pico (ex: 18h-20h)
        hora_atual = datetime.now().hour
        if 18 <= hora_atual <= 20:
            prob_atual *= 1.5
        elif 12 <= hora_atual <= 14:
            prob_atual *= 1.3
        
        return random.random() < prob_atual
    
    def exibir_status(self):
        """Exibe status atual da simulação"""
        periodo = self.get_periodo_atual()
        hora_atual = datetime.now().strftime('%H:%M:%S')
        
        print(f"\n{'='*60}")
        print(f"🕒 {hora_atual} - Período: {periodo['nome']} (Fator: {periodo['fator']}x)")
        print(f"📊 Vendas hoje: {self.vendas_dia_atual} | Faturamento: R$ {self.valor_total_dia:.2f}")
        print(f"👥 Clientes: {len(self.clientes_cache)} | 🛒 Produtos em estoque: {len(self.produtos_cache)}")
        print(f"{'='*60}\n")
    
    def executar_simulacao(self):
        """Executa a simulação em tempo real"""
        print("\n" + "="*60)
        print("🚀 SIMULADOR DE VENDAS EM TEMPO REAL")
        print("="*60)
        print("O script irá gerar vendas continuamente baseado no horário atual")
        print("Pressione Ctrl+C para parar")
        print("="*60 + "\n")
        
        # Verificar se já existem vendas hoje
        try:
            conn = mysql.connector.connect(**DB_CONFIG)
            cursor = conn.cursor()
            hoje = datetime.now().date()
            cursor.execute("""
                SELECT COUNT(*), COALESCE(SUM(valor_total), 0) 
                FROM pedidos 
                WHERE DATE(data_pedido) = %s
            """, (hoje,))
            result = cursor.fetchone()
            self.vendas_dia_atual = result[0] if result[0] else 0
            self.valor_total_dia = float(result[1]) if result[1] else 0.0
            cursor.close()
            conn.close()
            print(f"📊 Vendas já registradas hoje: {self.vendas_dia_atual} | R$ {self.valor_total_dia:.2f}\n")
        except Exception as e:
            print(f"⚠️ Erro ao verificar vendas do dia: {e}")
            pass
        
        # Loop principal
        ultima_atualizacao_cache = time.time()
        ultimo_status = time.time()
        
        try:
            while self.running:
                hora_atual = datetime.now()
                
                # Parar após meia-noite (opcional, pode continuar para próximo dia)
                if hora_atual.hour == 0 and hora_atual.minute == 0:
                    print("\n🌟 NOVO DIA INICIANDO! 🌟")
                    self.vendas_dia_atual = 0
                    self.valor_total_dia = 0.0
                    time.sleep(60)  # Esperar 1 minuto para evitar múltiplos reset
                    continue
                
                # Atualizar cache a cada 5 minutos
                if time.time() - ultima_atualizacao_cache > 300:
                    self.atualizar_cache_produtos()
                    ultima_atualizacao_cache = time.time()
                
                # Exibir status a cada 2 minutos
                if time.time() - ultimo_status > 120:
                    self.exibir_status()
                    ultimo_status = time.time()
                
                # Decidir se gera uma venda
                if self.should_generate_venda():
                    # Garantir que temos produtos em estoque
                    if not self.produtos_cache:
                        print("⚠️ Sem produtos em estoque! Aguardando...")
                        time.sleep(30)
                        continue
                    
                    # Obter cliente e processar pedido
                    cliente_id = self.obter_cliente()
                    if cliente_id:
                        pedido_id, valor = self.processar_pedido(cliente_id, datetime.now())
                        
                        if pedido_id:
                            self.vendas_dia_atual += 1
                            self.valor_total_dia += valor
                            
                            # Formatar mensagem da venda
                            produtos_info = ""
                            try:
                                conn = mysql.connector.connect(**DB_CONFIG)
                                cursor = conn.cursor()
                                cursor.execute("""
                                    SELECT p.nome, ip.quantidade 
                                    FROM itens_pedido ip
                                    JOIN produtos p ON ip.produto_id = p.id
                                    WHERE ip.pedido_id = %s
                                """, (pedido_id,))
                                produtos = cursor.fetchall()
                                produtos_info = f" - {len(produtos)} itens"
                                cursor.close()
                                conn.close()
                            except:
                                pass
                            
                            print(f"🛒 NOVA VENDA! Pedido #{pedido_id} | Cliente ID: {cliente_id} | R$ {valor:.2f}{produtos_info}")
                            print(f"   📊 Total hoje: {self.vendas_dia_atual} vendas | R$ {self.valor_total_dia:.2f}")
                    
                    # Aguardar entre vendas (mais realista)
                    periodo = self.get_periodo_atual()
                    intervalo = random.uniform(periodo['intervalo_segundos'] * 0.5, periodo['intervalo_segundos'] * 1.5)
                    time.sleep(intervalo)
                else:
                    # Pequena pausa antes de verificar novamente
                    time.sleep(5)
                    
        except KeyboardInterrupt:
            print("\n\n🛑 Simulação interrompida pelo usuário")
        except Exception as e:
            print(f"\n❌ Erro na simulação: {e}")
        finally:
            self.exibir_resumo_final()
    
    def exibir_resumo_final(self):
        """Exibe resumo do dia atual"""
        print("\n" + "="*60)
        print("📊 RESUMO DO DIA")
        print("="*60)
        print(f"Vendas realizadas: {self.vendas_dia_atual}")
        print(f"Faturamento total: R$ {self.valor_total_dia:.2f}")
        print(f"Ticket médio: R$ {(self.valor_total_dia / self.vendas_dia_atual) if self.vendas_dia_atual > 0 else 0:.2f}")
        
        # Estatísticas adicionais do dia
        try:
            conn = mysql.connector.connect(**DB_CONFIG)
            cursor = conn.cursor()
            hoje = datetime.now().date()
            
            # Top produtos do dia
            cursor.execute("""
                SELECT p.nome, SUM(ip.quantidade) as total_vendido
                FROM itens_pedido ip
                JOIN pedidos ped ON ip.pedido_id = ped.id
                JOIN produtos p ON ip.produto_id = p.id
                WHERE DATE(ped.data_pedido) = %s
                GROUP BY p.id
                ORDER BY total_vendido DESC
                LIMIT 5
            """, (hoje,))
            
            print("\n🏆 TOP 5 PRODUTOS DO DIA:")
            for i, (nome, qtd) in enumerate(cursor.fetchall(), 1):
                print(f"   {i}. {nome[:40]} - {qtd} unidades")
            
            # Meios de pagamento
            cursor.execute("""
                SELECT forma_pagamento, COUNT(*)
                FROM pagamentos p
                JOIN pedidos ped ON p.pedido_id = ped.id
                WHERE DATE(ped.data_pedido) = %s
                GROUP BY forma_pagamento
            """, (hoje,))
            
            print("\n💳 FORMAS DE PAGAMENTO:")
            for forma, qtd in cursor.fetchall():
                print(f"   {forma}: {qtd} pedidos")
            
            cursor.close()
            conn.close()
        except Exception as e:
            print(f"Erro ao obter estatísticas: {e}")
        
        print("="*60)

def simular_data_especifica(data_str):
    """Simula um dia específico (para testes ou backfill)"""
    try:
        data = datetime.strptime(data_str, '%Y-%m-%d')
        if data > datetime.now():
            print("❌ Não é possível simular datas futuras")
            return
        
        print(f"\n📅 Simulando vendas para {data.strftime('%Y-%m-%d')}")
        simulador = SimuladorVendasTempoReal()
        
        # Verificar se já existem vendas nesta data
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM pedidos WHERE DATE(data_pedido) = %s", (data.date(),))
        vendas_existentes = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        if vendas_existentes > 0:
            print(f"⚠️ Já existem {vendas_existentes} vendas para esta data")
            resposta = input("Deseja adicionar mais vendas? (s/N): ")
            if resposta.lower() != 's':
                return
        
        num_vendas = int(input("Quantas vendas deseja simular para este dia? (padrão: 50): ") or "50")
        
        for i in range(num_vendas):
            hora = random.randint(8, 22)
            minuto = random.randint(0, 59)
            segundo = random.randint(0, 59)
            data_pedido = data.replace(hour=hora, minute=minuto, second=segundo)
            
            cliente_id = simulador.obter_cliente()
            if cliente_id:
                pedido_id, valor = simulador.processar_pedido(cliente_id, data_pedido)
                if pedido_id:
                    print(f"   Venda {i+1}/{num_vendas}: Pedido #{pedido_id} - R$ {valor:.2f}")
            
            # Pequena pausa entre vendas
            time.sleep(random.uniform(0.1, 0.5))
        
        print(f"\n✅ Simulação para {data.strftime('%Y-%m-%d')} concluída!")
        
    except ValueError:
        print("❌ Formato de data inválido. Use YYYY-MM-DD")

def main():
    parser = argparse.ArgumentParser(description='Simulador de Vendas em Tempo Real')
    parser.add_argument('--data', type=str, help='Simular uma data específica (YYYY-MM-DD)')
    parser.add_argument('--backfill', type=int, help='Popular N dias anteriores (backfill)')
    
    args = parser.parse_args()
    
    if args.data:
        simular_data_especifica(args.data)
    elif args.backfill:
        print(f"📦 Populando últimos {args.backfill} dias...")
        for i in range(args.backfill, 0, -1):
            data = datetime.now() - timedelta(days=i)
            simular_data_especifica(data.strftime('%Y-%m-%d'))
            time.sleep(1)
    else:
        # Modo normal: simulação em tempo real
        simulador = SimuladorVendasTempoReal()
        simulador.executar_simulacao()

if __name__ == "__main__":
    main()