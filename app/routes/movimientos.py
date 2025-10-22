# =============================================
# RUTAS DE MOVIMIENTOS - SGI-GuateMart
# app/routes/movimientos.py
# ACTUALIZADO CON SISTEMA DE ROLES
# =============================================

from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from app.routes.auth import login_required, role_required
from app.database import execute_query, execute_procedure, puede_registrar_movimientos, puede_resolver_alertas

bp = Blueprint('movimientos', __name__, url_prefix='/movimientos')


@bp.route('/')
@login_required
def listar():
    """Lista los movimientos de inventario - TODOS LOS ROLES pueden ver"""
    
    # Obtener filtros
    filtro = request.args.get('q', '')
    tipo = request.args.get('tipo', '')
    page = int(request.args.get('page', 1))
    per_page = 20
    offset = (page - 1) * per_page
    
    try:
        query = """
            SELECT 
                m.id_movimiento,
                m.fecha_movimiento,
                p.sku,
                p.nombre_producto,
                tm.nombre_tipo,
                m.cantidad,
                m.stock_anterior,
                m.stock_nuevo,
                u.nombre_completo AS usuario,
                m.numero_documento
            FROM Movimientos m
            INNER JOIN Productos p ON m.id_producto = p.id_producto
            INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
            INNER JOIN Usuarios u ON m.id_usuario = u.id_usuario
            WHERE 1=1
        """
        
        params = []
        
        if filtro:
            query += " AND (p.sku LIKE ? OR p.nombre_producto LIKE ?)"
            params.extend([f'%{filtro}%', f'%{filtro}%'])
        
        if tipo:
            query += " AND m.id_tipo_movimiento = ?"
            params.append(tipo)
        
        query += f" ORDER BY m.fecha_movimiento DESC OFFSET {offset} ROWS FETCH NEXT {per_page} ROWS ONLY"
        
        movimientos = execute_query(query, tuple(params) if params else None)
        
        # Contar total
        query_count = "SELECT COUNT(*) as total FROM Movimientos m INNER JOIN Productos p ON m.id_producto = p.id_producto WHERE 1=1"
        params_count = []
        
        if filtro:
            query_count += " AND (p.sku LIKE ? OR p.nombre_producto LIKE ?)"
            params_count.extend([f'%{filtro}%', f'%{filtro}%'])
        
        if tipo:
            query_count += " AND m.id_tipo_movimiento = ?"
            params_count.append(tipo)
        
        total_result = execute_query(query_count, tuple(params_count) if params_count else None)
        total = total_result[0]['total'] if total_result else 0
        total_pages = (total + per_page - 1) // per_page
        
        # Obtener tipos de movimiento para el filtro
        tipos_movimiento = execute_query("SELECT * FROM TiposMovimiento WHERE activo = 1")
        
        # NUEVO: Verificar permisos del usuario actual
        rol_usuario = session.get('rol')
        puede_registrar = puede_registrar_movimientos(rol_usuario)
        
        return render_template(
            'movimientos/listar.html',
            movimientos=movimientos,
            tipos_movimiento=tipos_movimiento,
            filtro=filtro,
            tipo_seleccionado=tipo,
            page=page,
            total_pages=total_pages,
            total=total,
            puede_registrar=puede_registrar  # NUEVO: Pasar permiso al template
        )
        
    except Exception as e:
        print(f"Error al listar movimientos: {e}")
        flash('Error al cargar movimientos', 'error')
        return render_template('movimientos/listar.html', movimientos=[], error=str(e))


@bp.route('/registrar', methods=['GET', 'POST'])
@login_required
@role_required('Administrador', 'Operador de Bodega')  # ACTUALIZADO: Roles correctos
def registrar():
    """
    Registrar un nuevo movimiento de inventario
    SOLO: Administrador y Operador de Bodega
    """
    
    if request.method == 'POST':
        try:
            id_producto = int(request.form.get('id_producto'))
            id_tipo_movimiento = int(request.form.get('id_tipo_movimiento'))
            cantidad = int(request.form.get('cantidad'))
            id_usuario = session.get('user_id')
            id_proveedor = request.form.get('id_proveedor')
            numero_documento = request.form.get('numero_documento')
            observaciones = request.form.get('observaciones')
            
            # Validar datos
            if cantidad <= 0:
                flash('La cantidad debe ser mayor a 0', 'error')
                return redirect(url_for('movimientos.registrar'))
            
            # Usar procedimiento almacenado
            params = {
                'id_producto': id_producto,
                'id_tipo_movimiento': id_tipo_movimiento,
                'cantidad': cantidad,
                'id_usuario': id_usuario,
                'id_proveedor': id_proveedor if id_proveedor else None,
                'numero_documento': numero_documento if numero_documento else None,
                'observaciones': observaciones if observaciones else None
            }
            
            result = execute_procedure('sp_RegistrarMovimiento', params)
            
            flash('Movimiento registrado exitosamente', 'success')
            return redirect(url_for('movimientos.listar'))
            
        except Exception as e:
            print(f"Error al registrar movimiento: {e}")
            flash(f'Error al registrar movimiento: {str(e)}', 'error')
    
    # Obtener datos para el formulario
    productos = execute_query("SELECT id_producto, sku, nombre_producto, stock_actual FROM Productos WHERE activo = 1 ORDER BY nombre_producto")
    tipos_movimiento = execute_query("SELECT * FROM TiposMovimiento WHERE activo = 1 ORDER BY nombre_tipo")
    proveedores = execute_query("SELECT * FROM Proveedores WHERE activo = 1 ORDER BY nombre_proveedor")
    
    return render_template(
        'movimientos/registrar.html',
        productos=productos,
        tipos_movimiento=tipos_movimiento,
        proveedores=proveedores
    )


@bp.route('/alertas')
@login_required
def alertas():
    """Ver todas las alertas de stock - TODOS LOS ROLES pueden ver"""
    
    try:
        query = """
            SELECT 
                a.*,
                p.sku,
                p.nombre_producto,
                p.stock_actual,
                c.nombre_categoria,
                pr.nombre_proveedor
            FROM AlertasStock a
            INNER JOIN Productos p ON a.id_producto = p.id_producto
            LEFT JOIN Categorias c ON p.id_categoria = c.id_categoria
            LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor
            WHERE a.estado = 'PENDIENTE'
            ORDER BY 
                CASE a.tipo_alerta
                    WHEN 'STOCK_CRITICO' THEN 1
                    WHEN 'STOCK_MINIMO' THEN 2
                END,
                a.fecha_generacion DESC
        """
        
        alertas = execute_query(query)
        
        # NUEVO: Verificar si el usuario puede resolver alertas
        rol_usuario = session.get('rol')
        puede_resolver = puede_resolver_alertas(rol_usuario)
        
        return render_template(
            'movimientos/alertas.html', 
            alertas=alertas,
            puede_resolver=puede_resolver  # NUEVO: Pasar permiso al template
        )
        
    except Exception as e:
        print(f"Error al listar alertas: {e}")
        flash('Error al cargar alertas', 'error')
        return render_template('movimientos/alertas.html', alertas=[], error=str(e))


@bp.route('/alertas/<int:id>/resolver', methods=['POST'])
@login_required
@role_required('Administrador')  # ACTUALIZADO: Solo Administrador puede resolver
def resolver_alerta(id):
    """
    Marcar una alerta como resuelta
    SOLO: Administrador
    """
    
    try:
        id_usuario = session.get('user_id')
        query = """
            UPDATE AlertasStock 
            SET estado = 'RESUELTA',
                fecha_resolucion = GETDATE(),
                id_usuario_resolucion = ?
            WHERE id_alerta = ?
        """
        execute_query(query, (id_usuario, id), fetch=False)
        flash('Alerta resuelta exitosamente', 'success')
    except Exception as e:
        print(f"Error al resolver alerta: {e}")
        flash('Error al resolver alerta', 'error')
    
    return redirect(url_for('movimientos.alertas'))