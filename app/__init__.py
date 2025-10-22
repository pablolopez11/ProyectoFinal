# =============================================
# INICIALIZADOR DE FLASK - SGI-GuateMart
# app/__init__.py
# =============================================

from flask import Flask
from flask_session import Session
from config import get_config

# Inicializar extensión de sesiones
sess = Session()


def create_app(config_name='default'):
    """Factory para crear la aplicación Flask"""
    
    # Crear instancia de Flask
    app = Flask(__name__)
    
    # Cargar configuración
    app.config.from_object(get_config(config_name))
    
    # Inicializar sesiones
    sess.init_app(app)
    
    # Registrar blueprints (rutas)
    from app.routes import auth, dashboard, productos, movimientos
    
    app.register_blueprint(auth.bp)
    app.register_blueprint(dashboard.bp)
    app.register_blueprint(productos.bp)
    app.register_blueprint(movimientos.bp)
    
    # Ruta raíz redirige al dashboard
    @app.route('/')
    def index():
        from flask import redirect, url_for
        return redirect(url_for('auth.login'))
    
    # Context processor para variables globales en templates
    @app.context_processor
    def inject_globals():
        return {
            'app_name': app.config['APP_NAME'],
            'app_version': app.config['APP_VERSION']
        }
    
    return app