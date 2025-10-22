# =============================================
# MÓDULO DE BASE DE DATOS - SGI-GuateMart
# app/database.py
# ACTUALIZADO CON SISTEMA DE ROLES
# =============================================

import pyodbc
from flask import current_app, g


def get_db():
    """
    Obtiene la conexión a la base de datos.
    Se reutiliza durante el contexto de la petición.
    """
    if 'db' not in g:
        try:
            g.db = pyodbc.connect(
                current_app.config['DB_CONNECTION_STRING'],
                timeout=10
            )
            g.db.autocommit = False  # Manejar transacciones manualmente
        except pyodbc.Error as e:
            print(f"Error al conectar a la base de datos: {e}")
            raise
    
    return g.db


def close_db(e=None):
    """Cierra la conexión a la base de datos al final de la petición"""
    db = g.pop('db', None)
    
    if db is not None:
        db.close()


def init_app(app):
    """Registra la función de cierre en la aplicación"""
    app.teardown_appcontext(close_db)


def execute_query(query, params=None, fetch=True):
    """
    Ejecuta una consulta SQL y retorna los resultados.
    
    Args:
        query (str): Consulta SQL
        params (tuple): Parámetros para la consulta
        fetch (bool): Si debe retornar resultados (SELECT) o no (INSERT/UPDATE)
    
    Returns:
        list: Lista de resultados si fetch=True
        int: Número de filas afectadas si fetch=False
    """
    db = get_db()
    cursor = db.cursor()
    
    try:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        
        if fetch:
            # Para SELECT
            columns = [column[0] for column in cursor.description]
            results = []
            for row in cursor.fetchall():
                results.append(dict(zip(columns, row)))
            return results
        else:
            # Para INSERT, UPDATE, DELETE
            db.commit()
            return cursor.rowcount
            
    except pyodbc.Error as e:
        db.rollback()
        print(f"Error en consulta SQL: {e}")
        raise
    finally:
        cursor.close()


def execute_procedure(proc_name, params=None):
    """
    Ejecuta un procedimiento almacenado.
    
    Args:
        proc_name (str): Nombre del procedimiento
        params (dict): Parámetros del procedimiento
    
    Returns:
        list: Resultados del procedimiento
    """
    db = get_db()
    cursor = db.cursor()
    
    try:
        if params:
            # Construir llamada al procedimiento
            placeholders = ', '.join(['?' for _ in params])
            call = f"EXEC {proc_name} {placeholders}"
            cursor.execute(call, list(params.values()))
        else:
            cursor.execute(f"EXEC {proc_name}")
        
        # Obtener resultados
        results = []
        if cursor.description:
            columns = [column[0] for column in cursor.description]
            for row in cursor.fetchall():
                results.append(dict(zip(columns, row)))
        
        db.commit()
        return results
        
    except pyodbc.Error as e:
        db.rollback()
        print(f"Error al ejecutar procedimiento {proc_name}: {e}")
        raise
    finally:
        cursor.close()


# =============================================
# FUNCIONES HELPER PARA CONSULTAS COMUNES
# =============================================

def get_user_by_username(username):
    """Obtiene un usuario por su nombre de usuario"""
    query = """
        SELECT u.id_usuario, u.username, u.password_hash, u.nombre_completo,
               u.email, u.id_rol, r.nombre_rol, r.descripcion as descripcion_rol, u.activo
        FROM Usuarios u
        INNER JOIN Roles r ON u.id_rol = r.id_rol
        WHERE u.username = ? AND u.activo = 1
    """
    results = execute_query(query, (username,))
    return results[0] if results else None


def update_last_access(user_id):
    """Actualiza la última fecha de acceso del usuario"""
    query = "UPDATE Usuarios SET ultimo_acceso = GETDATE() WHERE id_usuario = ?"
    execute_query(query, (user_id,), fetch=False)


def get_productos(filtro=None, limit=None, offset=None):
    """Obtiene lista de productos con filtros opcionales"""
    query = """
        SELECT p.id_producto, p.sku, p.codigo_barras, p.nombre_producto,
               p.stock_actual, p.stock_minimo, p.stock_maximo,
               p.precio_compra, p.precio_venta,
               c.nombre_categoria, pr.nombre_proveedor
        FROM Productos p
        LEFT JOIN Categorias c ON p.id_categoria = c.id_categoria
        LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor
        WHERE p.activo = 1
    """
    
    params = []
    
    if filtro:
        query += " AND (p.sku LIKE ? OR p.nombre_producto LIKE ?)"
        params.extend([f'%{filtro}%', f'%{filtro}%'])
    
    query += " ORDER BY p.nombre_producto"
    
    if limit:
        query += f" OFFSET {offset or 0} ROWS FETCH NEXT {limit} ROWS ONLY"
    
    return execute_query(query, tuple(params) if params else None)


def get_alertas_stock():
    """Obtiene productos con stock bajo"""
    query = "SELECT * FROM vw_ProductosStockBajo ORDER BY nivel_alerta, stock_actual"
    return execute_query(query)


def get_dashboard_stats():
    """Obtiene estadísticas para el dashboard"""
    return execute_procedure('sp_ObtenerDashboard')


# =============================================
# FUNCIONES DE PERMISOS Y ROLES - NUEVO
# =============================================

def get_rol_info(id_rol):
    """Obtiene información detallada de un rol"""
    query = "SELECT * FROM Roles WHERE id_rol = ?"
    results = execute_query(query, (id_rol,))
    return results[0] if results else None


def get_all_roles():
    """Obtiene todos los roles activos del sistema"""
    query = "SELECT * FROM Roles ORDER BY id_rol"
    return execute_query(query)


def puede_registrar_movimientos(rol_nombre):
    """
    Verifica si un rol puede registrar movimientos de inventario
    
    Returns:
        bool: True si puede registrar movimientos, False si solo lectura
    """
    roles_con_movimientos = ['Administrador', 'Operador de Bodega']
    return rol_nombre in roles_con_movimientos


def puede_crear_productos(rol_nombre):
    """
    Verifica si un rol puede crear nuevos productos
    
    Returns:
        bool: True si puede crear productos
    """
    roles_crear_productos = ['Administrador', 'Operador de Bodega']
    return rol_nombre in roles_crear_productos


def puede_editar_productos(rol_nombre):
    """
    Verifica si un rol puede editar productos
    
    Returns:
        bool: True si puede editar productos
    """
    roles_editar_productos = ['Administrador', 'Operador de Bodega']
    return rol_nombre in roles_editar_productos


def puede_eliminar_productos(rol_nombre):
    """
    Verifica si un rol puede eliminar productos
    
    Returns:
        bool: True si puede eliminar, False en caso contrario
    """
    roles_con_eliminacion = ['Administrador']
    return rol_nombre in roles_con_eliminacion


def puede_ver_precios(rol_nombre):
    """
    Verifica si un rol puede ver información financiera (precios)
    
    Returns:
        bool: True si puede ver precios, False en caso contrario
    """
    roles_con_precios = ['Administrador', 'Operador de Bodega']
    return rol_nombre in roles_con_precios


def puede_resolver_alertas(rol_nombre):
    """
    Verifica si un rol puede resolver alertas de stock
    
    Returns:
        bool: True si puede resolver alertas
    """
    roles_resolver_alertas = ['Administrador']
    return rol_nombre in roles_resolver_alertas


def puede_gestionar_usuarios(rol_nombre):
    """
    Verifica si un rol puede gestionar usuarios del sistema
    
    Returns:
        bool: True si puede gestionar usuarios, False en caso contrario
    """
    roles_con_gestion_usuarios = ['Administrador']
    return rol_nombre in roles_con_gestion_usuarios


def get_permisos_usuario(rol_nombre):
    """
    Obtiene un diccionario completo de permisos para un rol
    
    Args:
        rol_nombre (str): Nombre del rol
    
    Returns:
        dict: Diccionario con todos los permisos del rol
    """
    return {
        # Permisos de productos
        'puede_crear_productos': puede_crear_productos(rol_nombre),
        'puede_editar_productos': puede_editar_productos(rol_nombre),
        'puede_eliminar_productos': puede_eliminar_productos(rol_nombre),
        
        # Permisos de movimientos
        'puede_registrar_movimientos': puede_registrar_movimientos(rol_nombre),
        'puede_resolver_alertas': puede_resolver_alertas(rol_nombre),
        
        # Permisos de visualización
        'puede_ver_precios': puede_ver_precios(rol_nombre),
        
        # Permisos administrativos
        'puede_gestionar_usuarios': puede_gestionar_usuarios(rol_nombre),
        
        # Identificadores de rol
        'es_administrador': rol_nombre == 'Administrador',
        'es_operador': rol_nombre == 'Operador de Bodega',
        'es_consulta': rol_nombre == 'Usuario de Consulta'
    }