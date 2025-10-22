# =============================================
# RUTAS DEL DASHBOARD - SGI-GuateMart
# app/routes/dashboard.py
# ACTUALIZADO CON SISTEMA DE ROLES
# =============================================

from flask import Blueprint, render_template, g, session
from app.routes.auth import login_required
from app.database import (
    get_dashboard_stats, get_alertas_stock, execute_query,
    get_permisos_usuario, puede_ver_precios
)

bp = Blueprint('dashboard', __name__, url_prefix='/dashboard')


@bp.route('/')
@login_required
def index():
    """Dashboard principal - Contenido según rol del usuario"""
    
    try:
        # NUEVO: Obtener rol y permisos del usuario
        rol_usuario = session.get('rol')
        permisos = get_permisos_usuario(rol_usuario)
        puede_ver_finanzas = puede_ver_precios(rol_usuario)
        
        # Obtener estadísticas del dashboard
        stats_results = get_dashboard_stats()
        
        # El procedimiento retorna 4 resultsets
        stats_general = stats_results[0] if len(stats_results) > 0 and stats_results[0] else {}
        productos_vendidos = stats_results[1] if len(stats_results) > 1 else []
        alertas_count = stats_results[2] if len(stats_results) > 2 and stats_results[2] else {'alertas_pendientes': 0}
        movimientos_recientes = stats_results[3] if len(stats_results) > 3 else []
        
        # NUEVO: Filtrar información financiera según permisos
        if not puede_ver_finanzas:
            # Usuario de Consulta: Ocultar información financiera
            if stats_general:
                # Mantener solo información de cantidades, remover valores monetarios
                stats_filtrado = {
                    'total_productos': stats_general.get('total_productos', 0),
                    'stock_total': stats_general.get('stock_total', 0),
                    'productos_bajo_stock': stats_general.get('productos_bajo_stock', 0),
                    'movimientos_hoy': stats_general.get('movimientos_hoy', 0)
                }
                stats_general = stats_filtrado
        
        # Obtener alertas de stock
        alertas = get_alertas_stock()
        
        # Obtener movimientos recientes (últimos 10)
        query_movimientos = """
            SELECT TOP 10
                m.fecha_movimiento,
                p.nombre_producto,
                tm.nombre_tipo,
                m.cantidad,
                u.nombre_completo
            FROM Movimientos m
            INNER JOIN Productos p ON m.id_producto = p.id_producto
            INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
            INNER JOIN Usuarios u ON m.id_usuario = u.id_usuario
            ORDER BY m.fecha_movimiento DESC
        """
        movimientos = execute_query(query_movimientos)
        
        return render_template(
            'dashboard.html',
            stats=stats_general,
            productos_vendidos=productos_vendidos[:5],  # Top 5
            alertas=alertas[:5],  # Primeras 5 alertas
            alertas_total=len(alertas),
            movimientos=movimientos,
            permisos=permisos,  # NUEVO: Pasar permisos al template
            puede_ver_finanzas=puede_ver_finanzas  # NUEVO: Flag específico para finanzas
        )
        
    except Exception as e:
        print(f"Error en dashboard: {e}")
        
        # NUEVO: Obtener permisos incluso en caso de error
        rol_usuario = session.get('rol', 'Usuario de Consulta')
        permisos = get_permisos_usuario(rol_usuario)
        
        return render_template(
            'dashboard.html',
            stats={},
            productos_vendidos=[],
            alertas=[],
            alertas_total=0,
            movimientos=[],
            permisos=permisos,
            puede_ver_finanzas=False,
            error="Error al cargar estadísticas"
        )