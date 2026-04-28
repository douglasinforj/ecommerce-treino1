import mysql.connector

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'admin',
    'database': 'ecommerce_vendas'
}

def limpar_tabelas():
    """Remove todos os dados das tabelas"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Desabilitar verificação de chaves estrangeiras
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        
        # Lista de tabelas na ordem correta (filhas primeiro)
        tabelas = [
            'rastreamento_log',
            'entregas', 
            'pagamentos',
            'itens_pedido',
            'pedidos',
            'produtos',
            'clientes'
        ]
        
        # Limpar cada tabela
        for tabela in tabelas:
            print(f"Limpando tabela: {tabela}")
            cursor.execute(f"DELETE FROM {tabela}")
            # Resetar AUTO_INCREMENT
            cursor.execute(f"ALTER TABLE {tabela} AUTO_INCREMENT = 1")
        
        # Reabilitar verificação de chaves estrangeiras
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        conn.commit()
        
        # Verificar resultado
        for tabela in tabelas:
            cursor.execute(f"SELECT COUNT(*) FROM {tabela}")
            count = cursor.fetchone()[0]
            print(f"  ✅ {tabela}: {count} registros")
        
        print("\n✅ Todas as tabelas foram limpas com sucesso!")
        
        cursor.close()
        conn.close()
        
    except mysql.connector.Error as err:
        print(f"❌ Erro: {err}")

if __name__ == "__main__":
    resposta = input("⚠️ Isso irá apagar TODOS os dados. Tem certeza? (s/N): ")
    if resposta.lower() == 's':
        limpar_tabelas()
    else:
        print("Operação cancelada.")