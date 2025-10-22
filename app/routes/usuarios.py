# =============================================
# RUTAS DE ADMINISTRACIÓN DE USUARIOS - SGI-GuateMart
# app/routes/usuarios.py
# =============================================

from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from app.routes.auth import login_required, role_required
from app.database import execute_query, get_all_roles

bp = Blueprint('usuarios', __name__, url_prefix='/usuarios')


@bp.route('/')
@login_required
@role_required('Administrador')
def listar():
    """
    Lista todos los usuarios del sistema
    SOLO: Administrador
    """
    
    # Obtener filtros
    filtro = request.args.get('q', '')
    rol_filtro = request.args.get('rol', '')
    estado = request.args.get('estado', '')
    page = int(request.args.get('page', 1))
    per_page = 20
    offset = (page - 1) * per_page
    
    try:
        query = """
            SELECT 
                u.id_usuario,
                u.username,
                u.nombre_completo,
                u.email,
                r.nombre_rol,
                r.id_rol,
                u.activo,
                u.fecha_creacion,
                u.ultimo_acceso
            FROM Usuarios u
            INNER JOIN Roles r ON u.id_rol = r.id_rol
            WHERE 1=1
        """
        
        params = []
        
        # Filtro de búsqueda
        if filtro:
            query += " AND (u.username LIKE ? OR u.nombre_completo LIKE ? OR u.email LIKE ?)"
            params.extend([f'%{filtro}%', f'%{filtro}%', f'%{filtro}%'])
        
        # Filtro por rol
        if rol_filtro:
            query += " AND u.id_rol = ?"
            params.append(rol_filtro)
        
        # Filtro por estado
        if estado:
            if estado == 'activos':
                query += " AND u.activo = 1"
            elif estado == 'inactivos':
                query += " AND u.activo = 0"
        
        query += f" ORDER BY u.fecha_creacion DESC OFFSET {offset} ROWS FETCH NEXT {per_page} ROWS ONLY"
        
        usuarios = execute_query(query, tuple(params) if params else None)
        
        # Contar total
        query_count = "SELECT COUNT(*) as total FROM Usuarios u WHERE 1=1"
        params_count = []
        
        if filtro:
            query_count += " AND (u.username LIKE ? OR u.nombre_completo LIKE ? OR u.email LIKE ?)"
            params_count.extend([f'%{filtro}%', f'%{filtro}%', f'%{filtro}%'])
        
        if rol_filtro:
            query_count += " AND u.id_rol = ?"
            params_count.append(rol_filtro)
        
        if estado:
            if estado == 'activos':
                query_count += " AND u.activo = 1"
            elif estado == 'inactivos':
                query_count += " AND u.activo = 0"
        
        total_result = execute_query(query_count, tuple(params_count) if params_count else None)
        total = total_result[0]['total'] if total_result else 0
        total_pages = (total + per_page - 1) // per_page
        
        # Obtener roles para el filtro
        roles = get_all_roles()
        
        return render_template(
            'usuarios/listar.html',
            usuarios=usuarios,
            roles=roles,
            filtro=filtro,
            rol_filtro=rol_filtro,
            estado=estado,
            page=page,
            total_pages=total_pages,
            total=total
        )
        
    except Exception as e:
        print(f"Error al listar usuarios: {e}")
        flash('Error al cargar usuarios', 'error')
        return render_template('usuarios/listar.html', usuarios=[], roles=[], error=str(e))


@bp.route('/crear', methods=['GET', 'POST'])
@login_required
@role_required('Administrador')
def crear():
    """
    Crear un nuevo usuario
    SOLO: Administrador
    """
    
    if request.method == 'POST':
        try:
            # Obtener datos del formulario
            username = request.form.get('username').strip()
            password = request.form.get('password')
            password_confirm = request.form.get('password_confirm')
            nombre_completo = request.form.get('nombre_completo').strip()
            email = request.form.get('email').strip()
            id_rol = int(request.form.get('id_rol'))
            
            # Validaciones
            if not username or not password or not nombre_completo or not email:
                flash('Todos los campos son obligatorios', 'error')
                return redirect(url_for('usuarios.crear'))
            
            if len(username) < 3:
                flash('El nombre de usuario debe tener al menos 3 caracteres', 'error')
                return redirect(url_for('usuarios.crear'))
            
            if len(password) < 6:
                flash('La contraseña debe tener al menos 6 caracteres', 'error')
                return redirect(url_for('usuarios.crear'))
            
            if password != password_confirm:
                flash('Las contraseñas no coinciden', 'error')
                return redirect(url_for('usuarios.crear'))
            
            # Validar que el username no exista
            query_check = "SELECT COUNT(*) as existe FROM Usuarios WHERE username = ?"
            result = execute_query(query_check, (username,))
            if result[0]['existe'] > 0:
                flash('El nombre de usuario ya existe', 'error')
                return redirect(url_for('usuarios.crear'))
            
            # Validar que el email no exista
            query_check_email = "SELECT COUNT(*) as existe FROM Usuarios WHERE email = ?"
            result_email = execute_query(query_check_email, (email,))
            if result_email[0]['existe'] > 0:
                flash('El correo electrónico ya está registrado', 'error')
                return redirect(url_for('usuarios.crear'))
            
            # Insertar usuario
            # NOTA: En producción, la contraseña DEBE ser hasheada con bcrypt o similar
            # Por ahora usamos texto plano como en el login actual
            query_insert = """
                INSERT INTO Usuarios (
                    username, password_hash, nombre_completo, email, 
                    id_rol, activo, fecha_creacion
                )
                VALUES (?, ?, ?, ?, ?, 1, GETDATE())
            """
            
            execute_query(
                query_insert,
                (username, password, nombre_completo, email, id_rol),
                fetch=False
            )
            
            flash(f'Usuario {username} creado exitosamente', 'success')
            return redirect(url_for('usuarios.listar'))
            
        except Exception as e:
            print(f"Error al crear usuario: {e}")
            flash(f'Error al crear usuario: {str(e)}', 'error')
    
    # Obtener roles para el formulario
    roles = get_all_roles()
    
    return render_template('usuarios/crear.html', roles=roles)


@bp.route('/<int:id>/editar', methods=['GET', 'POST'])
@login_required
@role_required('Administrador')
def editar(id):
    """
    Editar un usuario existente
    SOLO: Administrador
    """
    
    # Obtener usuario
    query_usuario = """
        SELECT u.*, r.nombre_rol
        FROM Usuarios u
        INNER JOIN Roles r ON u.id_rol = r.id_rol
        WHERE u.id_usuario = ?
    """
    usuarios = execute_query(query_usuario, (id,))
    
    if not usuarios:
        flash('Usuario no encontrado', 'error')
        return redirect(url_for('usuarios.listar'))
    
    usuario = usuarios[0]
    
    # Prevenir que el admin se edite a sí mismo (opcional)
    if usuario['id_usuario'] == session.get('user_id'):
        flash('No puedes editar tu propio usuario', 'warning')
        return redirect(url_for('usuarios.listar'))
    
    if request.method == 'POST':
        try:
            # Obtener datos del formulario
            nombre_completo = request.form.get('nombre_completo').strip()
            email = request.form.get('email').strip()
            id_rol = int(request.form.get('id_rol'))
            activo = 1 if request.form.get('activo') else 0
            
            # Validaciones
            if not nombre_completo or not email:
                flash('El nombre y email son obligatorios', 'error')
                return redirect(url_for('usuarios.editar', id=id))
            
            # Validar que el email no exista en otro usuario
            query_check_email = "SELECT COUNT(*) as existe FROM Usuarios WHERE email = ? AND id_usuario != ?"
            result_email = execute_query(query_check_email, (email, id))
            if result_email[0]['existe'] > 0:
                flash('El correo electrónico ya está registrado en otro usuario', 'error')
                return redirect(url_for('usuarios.editar', id=id))
            
            # Actualizar usuario
            query_update = """
                UPDATE Usuarios SET
                    nombre_completo = ?,
                    email = ?,
                    id_rol = ?,
                    activo = ?,
                    fecha_modificacion = GETDATE()
                WHERE id_usuario = ?
            """
            
            execute_query(
                query_update,
                (nombre_completo, email, id_rol, activo, id),
                fetch=False
            )
            
            flash('Usuario actualizado exitosamente', 'success')
            return redirect(url_for('usuarios.listar'))
            
        except Exception as e:
            print(f"Error al actualizar usuario: {e}")
            flash(f'Error al actualizar usuario: {str(e)}', 'error')
    
    # Obtener roles
    roles = get_all_roles()
    
    return render_template('usuarios/editar.html', usuario=usuario, roles=roles)


@bp.route('/<int:id>/cambiar-password', methods=['GET', 'POST'])
@login_required
@role_required('Administrador')
def cambiar_password(id):
    """
    Cambiar contraseña de un usuario
    SOLO: Administrador
    """
    
    # Obtener usuario
    query_usuario = "SELECT * FROM Usuarios WHERE id_usuario = ?"
    usuarios = execute_query(query_usuario, (id,))
    
    if not usuarios:
        flash('Usuario no encontrado', 'error')
        return redirect(url_for('usuarios.listar'))
    
    usuario = usuarios[0]
    
    if request.method == 'POST':
        try:
            password = request.form.get('password')
            password_confirm = request.form.get('password_confirm')
            
            # Validaciones
            if not password or not password_confirm:
                flash('Debe ingresar la contraseña', 'error')
                return redirect(url_for('usuarios.cambiar_password', id=id))
            
            if len(password) < 6:
                flash('La contraseña debe tener al menos 6 caracteres', 'error')
                return redirect(url_for('usuarios.cambiar_password', id=id))
            
            if password != password_confirm:
                flash('Las contraseñas no coinciden', 'error')
                return redirect(url_for('usuarios.cambiar_password', id=id))
            
            # Actualizar contraseña
            # NOTA: En producción, la contraseña DEBE ser hasheada
            query_update = """
                UPDATE Usuarios SET
                    password_hash = ?,
                    fecha_modificacion = GETDATE()
                WHERE id_usuario = ?
            """
            
            execute_query(query_update, (password, id), fetch=False)
            
            flash(f'Contraseña actualizada para {usuario["username"]}', 'success')
            return redirect(url_for('usuarios.listar'))
            
        except Exception as e:
            print(f"Error al cambiar contraseña: {e}")
            flash(f'Error al cambiar contraseña: {str(e)}', 'error')
    
    return render_template('usuarios/cambiar_password.html', usuario=usuario)


@bp.route('/<int:id>/toggle-estado', methods=['POST'])
@login_required
@role_required('Administrador')
def toggle_estado(id):
    """
    Activar/Desactivar un usuario
    SOLO: Administrador
    """
    
    try:
        # Obtener usuario
        query_usuario = "SELECT * FROM Usuarios WHERE id_usuario = ?"
        usuarios = execute_query(query_usuario, (id,))
        
        if not usuarios:
            flash('Usuario no encontrado', 'error')
            return redirect(url_for('usuarios.listar'))
        
        usuario = usuarios[0]
        
        # Prevenir desactivar el propio usuario
        if usuario['id_usuario'] == session.get('user_id'):
            flash('No puedes desactivar tu propio usuario', 'warning')
            return redirect(url_for('usuarios.listar'))
        
        # Toggle estado
        nuevo_estado = 0 if usuario['activo'] == 1 else 1
        query_update = "UPDATE Usuarios SET activo = ?, fecha_modificacion = GETDATE() WHERE id_usuario = ?"
        execute_query(query_update, (nuevo_estado, id), fetch=False)
        
        estado_texto = 'activado' if nuevo_estado == 1 else 'desactivado'
        flash(f'Usuario {usuario["username"]} {estado_texto} exitosamente', 'success')
        
    except Exception as e:
        print(f"Error al cambiar estado: {e}")
        flash('Error al cambiar estado del usuario', 'error')
    
    return redirect(url_for('usuarios.listar'))


@bp.route('/<int:id>/ver')
@login_required
@role_required('Administrador')
def ver(id):
    """
    Ver detalles completos de un usuario
    SOLO: Administrador
    """
    
    query = """
        SELECT 
            u.*,
            r.nombre_rol,
            r.descripcion as descripcion_rol
        FROM Usuarios u
        INNER JOIN Roles r ON u.id_rol = r.id_rol
        WHERE u.id_usuario = ?
    """
    
    usuarios = execute_query(query, (id,))
    
    if not usuarios:
        flash('Usuario no encontrado', 'error')
        return redirect(url_for('usuarios.listar'))
    
    # Obtener estadísticas del usuario
    query_stats = """
        SELECT 
            (SELECT COUNT(*) FROM Movimientos WHERE id_usuario = ?) as total_movimientos,
            (SELECT MAX(fecha_movimiento) FROM Movimientos WHERE id_usuario = ?) as ultimo_movimiento
    """
    
    stats = execute_query(query_stats, (id, id))
    estadisticas = stats[0] if stats else {'total_movimientos': 0, 'ultimo_movimiento': None}
    
    return render_template('usuarios/ver.html', usuario=usuarios[0], estadisticas=estadisticas)