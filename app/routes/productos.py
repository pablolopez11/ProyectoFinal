# =============================================
# RUTAS DE PRODUCTOS - SGI-GuateMart
# app/routes/productos.py
# ACTUALIZADO CON SISTEMA DE ROLES
# =============================================

from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify, session
from app.routes.auth import login_required, role_required
from app.services.barcode_service import BarcodeService, ProductService
from app.database import (
    execute_query, get_productos, 
    puede_crear_productos, puede_editar_productos, 
    puede_eliminar_productos, puede_ver_precios,
    get_permisos_usuario
)

bp = Blueprint('productos', __name__, url_prefix='/productos')


@bp.route('/')
@login_required
def listar():
    """Lista todos los productos - TODOS LOS ROLES pueden ver"""
    
    # Obtener filtros
    filtro = request.args.get('q', '')
    page = int(request.args.get('page', 1))
    per_page = 20
    offset = (page - 1) * per_page
    
    try:
        # Obtener productos
        productos = get_productos(filtro=filtro if filtro else None, limit=per_page, offset=offset)
        
        # Contar total para paginación
        query_count = "SELECT COUNT(*) as total FROM Productos WHERE activo = 1"
        params_count = None
        
        if filtro:
            query_count += " AND (sku LIKE ? OR nombre_producto LIKE ?)"
            params_count = (f'%{filtro}%', f'%{filtro}%')
        
        total_result = execute_query(query_count, params_count)
        total = total_result[0]['total'] if total_result else 0
        total_pages = (total + per_page - 1) // per_page
        
        # NUEVO: Obtener permisos del usuario actual
        rol_usuario = session.get('rol')
        permisos = get_permisos_usuario(rol_usuario)
        
        return render_template(
            'productos/listar.html',
            productos=productos,
            filtro=filtro,
            page=page,
            total_pages=total_pages,
            total=total,
            permisos=permisos  # NUEVO: Pasar todos los permisos al template
        )
        
    except Exception as e:
        print(f"Error al listar productos: {e}")
        flash('Error al cargar productos', 'error')
        return render_template('productos/listar.html', productos=[], error=str(e))


@bp.route('/crear', methods=['GET', 'POST'])
@login_required
@role_required('Administrador', 'Operador de Bodega')  # ACTUALIZADO: Roles correctos
def crear():
    """
    Crear un nuevo producto
    SOLO: Administrador y Operador de Bodega
    """
    
    if request.method == 'POST':
        try:
            # Obtener datos del formulario
            sku = request.form.get('sku')
            codigo_barras = request.form.get('codigo_barras')
            nombre = request.form.get('nombre_producto')
            descripcion = request.form.get('descripcion')
            id_categoria = request.form.get('id_categoria')
            id_proveedor = request.form.get('id_proveedor')
            precio_compra = float(request.form.get('precio_compra', 0))
            precio_venta = float(request.form.get('precio_venta', 0))
            stock_actual = int(request.form.get('stock_actual', 0))
            stock_minimo = int(request.form.get('stock_minimo', 0))
            stock_maximo = int(request.form.get('stock_maximo', 0))
            ubicacion = request.form.get('ubicacion')
            
            # Validar SKU único
            query_check = "SELECT COUNT(*) as existe FROM Productos WHERE sku = ?"
            result = execute_query(query_check, (sku,))
            if result[0]['existe'] > 0:
                flash('El SKU ya existe', 'error')
                return redirect(url_for('productos.crear'))
            
            # Insertar producto
            query_insert = """
                INSERT INTO Productos (
                    sku, codigo_barras, nombre_producto, descripcion,
                    id_categoria, id_proveedor, precio_compra, precio_venta,
                    stock_actual, stock_minimo, stock_maximo, ubicacion, activo
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
            """
            
            execute_query(
                query_insert,
                (sku, codigo_barras, nombre, descripcion, id_categoria, id_proveedor,
                 precio_compra, precio_venta, stock_actual, stock_minimo, stock_maximo, ubicacion),
                fetch=False
            )
            
            flash(f'Producto {nombre} creado exitosamente', 'success')
            return redirect(url_for('productos.listar'))
            
        except Exception as e:
            print(f"Error al crear producto: {e}")
            flash(f'Error al crear producto: {str(e)}', 'error')
    
    # Obtener categorías y proveedores para el formulario
    categorias = execute_query("SELECT * FROM Categorias WHERE activo = 1 ORDER BY nombre_categoria")
    proveedores = execute_query("SELECT * FROM Proveedores WHERE activo = 1 ORDER BY nombre_proveedor")
    
    return render_template(
        'productos/crear.html',
        categorias=categorias,
        proveedores=proveedores
    )


@bp.route('/<int:id>/editar', methods=['GET', 'POST'])
@login_required
@role_required('Administrador', 'Operador de Bodega')  # ACTUALIZADO: Roles correctos
def editar(id):
    """
    Editar un producto existente
    SOLO: Administrador y Operador de Bodega
    """
    
    # Obtener producto
    query_producto = "SELECT * FROM Productos WHERE id_producto = ?"
    productos = execute_query(query_producto, (id,))
    
    if not productos:
        flash('Producto no encontrado', 'error')
        return redirect(url_for('productos.listar'))
    
    producto = productos[0]
    
    if request.method == 'POST':
        try:
            # Actualizar producto
            query_update = """
                UPDATE Productos SET
                    codigo_barras = ?,
                    nombre_producto = ?,
                    descripcion = ?,
                    id_categoria = ?,
                    id_proveedor = ?,
                    precio_compra = ?,
                    precio_venta = ?,
                    stock_minimo = ?,
                    stock_maximo = ?,
                    ubicacion = ?,
                    fecha_modificacion = GETDATE()
                WHERE id_producto = ?
            """
            
            execute_query(
                query_update,
                (
                    request.form.get('codigo_barras'),
                    request.form.get('nombre_producto'),
                    request.form.get('descripcion'),
                    request.form.get('id_categoria'),
                    request.form.get('id_proveedor'),
                    float(request.form.get('precio_compra', 0)),
                    float(request.form.get('precio_venta', 0)),
                    int(request.form.get('stock_minimo', 0)),
                    int(request.form.get('stock_maximo', 0)),
                    request.form.get('ubicacion'),
                    id
                ),
                fetch=False
            )
            
            flash('Producto actualizado exitosamente', 'success')
            return redirect(url_for('productos.listar'))
            
        except Exception as e:
            print(f"Error al actualizar producto: {e}")
            flash(f'Error al actualizar producto: {str(e)}', 'error')
    
    # Obtener categorías y proveedores
    categorias = execute_query("SELECT * FROM Categorias WHERE activo = 1 ORDER BY nombre_categoria")
    proveedores = execute_query("SELECT * FROM Proveedores WHERE activo = 1 ORDER BY nombre_proveedor")
    
    return render_template(
        'productos/editar.html',
        producto=producto,
        categorias=categorias,
        proveedores=proveedores
    )


@bp.route('/<int:id>/eliminar', methods=['POST'])
@login_required
@role_required('Administrador')  # ACTUALIZADO: Solo Administrador
def eliminar(id):
    """
    Eliminar (desactivar) un producto
    SOLO: Administrador
    """
    
    try:
        query = "UPDATE Productos SET activo = 0 WHERE id_producto = ?"
        execute_query(query, (id,), fetch=False)
        flash('Producto eliminado exitosamente', 'success')
    except Exception as e:
        print(f"Error al eliminar producto: {e}")
        flash('Error al eliminar producto', 'error')
    
    return redirect(url_for('productos.listar'))


@bp.route('/<int:id>/ver')
@login_required
def ver(id):
    """Ver detalles de un producto - TODOS LOS ROLES pueden ver"""
    
    query = """
        SELECT p.*, c.nombre_categoria, pr.nombre_proveedor
        FROM Productos p
        LEFT JOIN Categorias c ON p.id_categoria = c.id_categoria
        LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor
        WHERE p.id_producto = ?
    """
    
    productos = execute_query(query, (id,))
    
    if not productos:
        flash('Producto no encontrado', 'error')
        return redirect(url_for('productos.listar'))
    
    # Obtener historial de movimientos
    query_movimientos = """
        SELECT TOP 20 * FROM vw_HistorialMovimientos
        WHERE sku = (SELECT sku FROM Productos WHERE id_producto = ?)
        ORDER BY fecha_movimiento DESC
    """
    movimientos = execute_query(query_movimientos, (id,))
    
    # NUEVO: Obtener permisos del usuario actual
    rol_usuario = session.get('rol')
    permisos = get_permisos_usuario(rol_usuario)
    
    return render_template(
        'productos/ver.html',
        producto=productos[0],
        movimientos=movimientos,
        permisos=permisos  # NUEVO: Pasar permisos al template
    )
    
    
@bp.route('/buscar-barcode', methods=['POST'])
@login_required
def buscar_barcode():
    """
    Buscar información de producto por código de barras
    Endpoint AJAX para prellenar formulario
    """
    try:
        codigo_barras = request.json.get('codigo_barras', '')
        
        # Validar formato
        if not BarcodeService.validar_barcode(codigo_barras):
            return {
                'success': False,
                'error': 'Código de barras inválido. Debe tener 8, 12, 13 o 14 dígitos.'
            }
        
        # Buscar en API
        resultado = BarcodeService.buscar_por_barcode(codigo_barras)
        
        if resultado.get('encontrado'):
            # Prellenar datos
            datos_producto = ProductService.prellenar_producto(resultado)
            return {
                'success': True,
                'data': datos_producto,
                'mensaje': f'Producto encontrado en {resultado.get("fuente")}'
            }
        else:
            return {
                'success': False,
                'mensaje': 'Producto no encontrado. Puedes ingresar los datos manualmente.'
            }
            
    except Exception as e:
        return {
            'success': False,
            'error': f'Error al buscar: {str(e)}'
        }