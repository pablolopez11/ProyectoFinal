# =============================================
# CONFIGURACIÓN - SGI-GuateMart
# config.py
# =============================================

import os

class Config:
    """Configuración base de la aplicación"""
    
    # Clave secreta para Flask (cambiar en producción)
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-guatemart-2025'
    
    # =============================================
    # CONFIGURACIÓN DE BASE DE DATOS
    # Windows Authentication (Trusted Connection)
    # =============================================
    DB_SERVER = os.environ.get('DB_SERVER') or r'.\SQLEXPRESS'
    DB_NAME = os.environ.get('DB_NAME') or 'SGI_GuateMart'
    
    # Cadena de conexión - Windows Authentication
    DB_CONNECTION_STRING = (
        f'DRIVER={{SQL Server}};'
        f'SERVER={DB_SERVER};'
        f'DATABASE={DB_NAME};'
        f'Trusted_Connection=yes;'
    )
    
    # =============================================
    # CONFIGURACIÓN DE SESIONES
    # =============================================
    SESSION_TYPE = 'filesystem'
    SESSION_PERMANENT = False
    PERMANENT_SESSION_LIFETIME = 3600  # 1 hora
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    
    # =============================================
    # CONFIGURACIÓN GENERAL
    # =============================================
    APP_NAME = 'SGI-GuateMart'
    APP_VERSION = '1.0.0'
    ITEMS_PER_PAGE = 20
    
    # Uploads
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB
    UPLOAD_FOLDER = 'uploads'
    ALLOWED_EXTENSIONS = {'xlsx', 'xls', 'csv', 'pdf'}


class DevelopmentConfig(Config):
    """Configuración para desarrollo"""
    DEBUG = True
    TESTING = False


class ProductionConfig(Config):
    """Configuración para producción"""
    DEBUG = False
    TESTING = False
    SESSION_COOKIE_SECURE = True


# Diccionario de configuraciones
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}


def get_config(config_name='default'):
    """Obtiene la configuración según el nombre"""
    return config.get(config_name, config['default'])