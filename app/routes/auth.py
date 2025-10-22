# =============================================
# RUTAS DE AUTENTICACIÓN - SGI-GuateMart
# app/routes/auth.py
# =============================================

from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.database import get_user_by_username, update_last_access

bp = Blueprint('auth', __name__, url_prefix='/auth')


@bp.route('/login', methods=['GET', 'POST'])
def login():
    """Página de inicio de sesión"""
    
    # Si ya está logueado, redirigir al dashboard
    if 'user_id' in session:
        return redirect(url_for('dashboard.index'))
    
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        # Validar campos
        if not username or not password:
            flash('Por favor ingrese usuario y contraseña', 'error')
            return render_template('login.html')
        
        # Buscar usuario en la base de datos
        user = get_user_by_username(username)
        
        if user and user['password_hash'] == password:
            # Login exitoso
            session.clear()
            session['user_id'] = user['id_usuario']
            session['username'] = user['username']
            session['nombre_completo'] = user['nombre_completo']
            session['rol'] = user['nombre_rol']
            session['id_rol'] = user['id_rol']
            
            # Actualizar último acceso
            update_last_access(user['id_usuario'])
            
            flash(f'Bienvenido {user["nombre_completo"]}!', 'success')
            return redirect(url_for('dashboard.index'))
        else:
            flash('Usuario o contraseña incorrectos', 'error')
    
    return render_template('login.html')


@bp.route('/logout')
def logout():
    """Cerrar sesión"""
    nombre = session.get('nombre_completo', 'Usuario')
    session.clear()
    flash(f'Hasta luego {nombre}!', 'info')
    return redirect(url_for('auth.login'))


@bp.before_app_request
def load_logged_in_user():
    """Carga el usuario en cada petición"""
    user_id = session.get('user_id')
    
    if user_id is None:
        # No hay sesión activa
        from flask import g
        g.user = None
    else:
        # Hay sesión activa, cargar datos del usuario
        from flask import g
        g.user = {
            'id_usuario': session.get('user_id'),
            'username': session.get('username'),
            'nombre_completo': session.get('nombre_completo'),
            'rol': session.get('rol'),
            'id_rol': session.get('id_rol')
        }


def login_required(view):
    """Decorador para requerir login en una vista"""
    from functools import wraps
    from flask import g
    
    @wraps(view)
    def wrapped_view(**kwargs):
        if g.user is None:
            flash('Debe iniciar sesión para acceder', 'warning')
            return redirect(url_for('auth.login'))
        
        return view(**kwargs)
    
    return wrapped_view


def role_required(*roles):
    """Decorador para requerir un rol específico"""
    def decorator(view):
        from functools import wraps
        from flask import g, abort
        
        @wraps(view)
        def wrapped_view(**kwargs):
            if g.user is None:
                flash('Debe iniciar sesión para acceder', 'warning')
                return redirect(url_for('auth.login'))
            
            if g.user['rol'] not in roles:
                flash('No tiene permisos para acceder a esta sección', 'error')
                abort(403)
            
            return view(**kwargs)
        
        return wrapped_view
    return decorator