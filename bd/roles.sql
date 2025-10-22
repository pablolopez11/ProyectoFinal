-- =============================================
-- ACTUALIZAR ROLES - SGI-GuateMart
-- Según especificación del documento
-- =============================================

USE SGI_GuateMart;
GO

-- Actualizar roles existentes
UPDATE Roles SET 
    nombre_rol = 'Administrador',
    descripcion = 'Ingeniero en Sistemas o Administrador de Empresas. Control total del sistema, configuración, gestión de usuarios, generación de reportes ejecutivos'
WHERE id_rol = 1;

UPDATE Roles SET 
    nombre_rol = 'Operador de Bodega',
    descripcion = 'Técnico con experiencia en inventarios. Registro de movimientos, actualización de productos, consulta de stock'
WHERE id_rol = 3;

UPDATE Roles SET 
    nombre_rol = 'Usuario de Consulta',
    descripcion = 'Personal administrativo. Consulta de inventario, visualización de reportes'
WHERE id_rol = 4;

-- Eliminar rol "Gerente" si existe (lo reemplazamos por Operador de Bodega)
DELETE FROM Roles WHERE nombre_rol = 'Gerente';

-- Verificar roles actualizados
SELECT * FROM Roles ORDER BY id_rol;
GO

-- Crear usuarios de ejemplo para cada rol
-- Usuario Administrador (ya existe)
UPDATE Usuarios SET 
    nombre_completo = 'Carlos Administrador',
    email = 'admin@guatemart.com'
WHERE username = 'admin';

-- Usuario Operador de Bodega
IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE username = 'operador')
BEGIN
    INSERT INTO Usuarios (username, password_hash, nombre_completo, email, id_rol, activo)
    VALUES ('operador', 'bodega123', 'Juan Operador', 'operador@guatemart.com', 3, 1);
END

-- Usuario de Consulta
IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE username = 'consulta')
BEGIN
    INSERT INTO Usuarios (username, password_hash, nombre_completo, email, id_rol, activo)
    VALUES ('consulta', 'consulta123', 'María Consulta', 'consulta@guatemart.com', 4, 1);
END

-- Verificar usuarios
SELECT 
    u.username,
    u.nombre_completo,
    r.nombre_rol,
    u.email,
    u.activo
FROM Usuarios u
INNER JOIN Roles r ON u.id_rol = r.id_rol
ORDER BY r.id_rol;
GO

PRINT 'Roles y usuarios actualizados correctamente';