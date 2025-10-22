import pyodbc

print("=" * 60)
print("PROBANDO CONEXIÓN A SQL SERVER")
print("=" * 60)
print()

SERVER = r'.\SQLEXPRESS'
DATABASE = 'SGI_GuateMart'

conn_string = (
    'DRIVER={SQL Server};'
    f'SERVER={SERVER};'
    f'DATABASE={DATABASE};'
    'Trusted_Connection=yes;'
)

try:
    print(f"Conectando a: {SERVER}")
    print(f"Base de datos: {DATABASE}")
    print()
    
    conn = pyodbc.connect(conn_string, timeout=5)
    print("✓ Conexión exitosa!")
    print()
    
    cursor = conn.cursor()
    
    # Probar consultas
    cursor.execute("SELECT COUNT(*) FROM Productos")
    total_productos = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM Usuarios")
    total_usuarios = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM Categorias")
    total_categorias = cursor.fetchone()[0]
    
    print("📊 Datos en la base de datos:")
    print(f"   Productos: {total_productos}")
    print(f"   Usuarios: {total_usuarios}")
    print(f"   Categorías: {total_categorias}")
    print()
    
    # Ver roles
    print("👥 Roles disponibles:")
    cursor.execute("SELECT nombre_rol FROM Roles")
    for rol in cursor.fetchall():
        print(f"   - {rol[0]}")
    print()
    
    conn.close()
    
    print("=" * 60)
    print("✅ TODO FUNCIONA CORRECTAMENTE")
    print("=" * 60)
    print()
    print("🚀 Listo para crear la aplicación Flask!")
    
except pyodbc.Error as e:
    print("❌ ERROR DE CONEXIÓN")
    print()
    print(f"Detalles: {e}")
    print()
    print("Verifica:")
    print("  1. SQL Server está corriendo")
    print("  2. Nombre del servidor es correcto")
    print("  3. Base de datos existe")
    
except Exception as e:
    print(f"❌ ERROR: {e}")