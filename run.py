# =============================================
# ARCHIVO PRINCIPAL - SGI-GuateMart
# run.py - Ejecuta la aplicación Flask
# =============================================

import os
from app import create_app

# Obtener configuración del entorno (por defecto: development)
config_name = os.environ.get('FLASK_CONFIG', 'development')

# Crear aplicación
app = create_app(config_name)

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 INICIANDO SGI-GUATEMART")
    print("=" * 60)
    print(f"Entorno: {config_name}")
    print(f"Base de datos: {app.config['DB_NAME']}")
    print(f"Servidor: {app.config['DB_SERVER']}")
    print("=" * 60)
    print()
    print("📌 Accede a: http://127.0.0.1:5000")
    print("📌 Usuario por defecto: admin / admin123")
    print()
    print("Presiona CTRL+C para detener el servidor")
    print("=" * 60)
    print()
    
    # Ejecutar aplicación
    app.run(
        host='127.0.0.1',
        port=5000,
        debug=True
    )