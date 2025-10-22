-- =============================================
-- SCRIPT DE PRUEBAS - SGI-GuateMart
-- Verifica que la base de datos esté correctamente instalada
-- =============================================

USE SGI_GuateMart;
GO

PRINT '========================================';
PRINT 'INICIANDO PRUEBAS DE LA BASE DE DATOS';
PRINT '========================================';
PRINT '';

-- =============================================
-- PRUEBA 1: Verificar que todas las tablas existen
-- =============================================
PRINT '1. VERIFICANDO TABLAS...';
PRINT '';

DECLARE @TablasEsperadas TABLE (NombreTabla VARCHAR(50));
INSERT INTO @TablasEsperadas VALUES 
    ('Roles'),
    ('Usuarios'),
    ('Categorias'),
    ('Proveedores'),
    ('Productos'),
    ('TiposMovimiento'),
    ('Movimientos'),
    ('Auditoria'),
    ('AlertasStock');

SELECT 
    te.NombreTabla,
    CASE WHEN t.name IS NOT NULL THEN '✓ OK' ELSE '✗ FALTA' END AS Estado
FROM @TablasEsperadas te
LEFT JOIN sys.tables t ON te.NombreTabla = t.name
ORDER BY te.NombreTabla;

PRINT '';

-- =============================================
-- PRUEBA 2: Verificar datos iniciales
-- =============================================
PRINT '2. VERIFICANDO DATOS INICIALES...';
PRINT '';

-- Roles
DECLARE @TotalRoles INT;
SELECT @TotalRoles = COUNT(*) FROM Roles;
PRINT '   Roles: ' + CAST(@TotalRoles AS VARCHAR) + ' registros ' + 
    CASE WHEN @TotalRoles = 4 THEN '✓' ELSE '✗' END;

-- Usuarios
DECLARE @TotalUsuarios INT;
SELECT @TotalUsuarios = COUNT(*) FROM Usuarios;
PRINT '   Usuarios: ' + CAST(@TotalUsuarios AS VARCHAR) + ' registros ' + 
    CASE WHEN @TotalUsuarios >= 1 THEN '✓' ELSE '✗' END;

-- Categorías
DECLARE @TotalCategorias INT;
SELECT @TotalCategorias = COUNT(*) FROM Categorias;
PRINT '   Categorías: ' + CAST(@TotalCategorias AS VARCHAR) + ' registros ' + 
    CASE WHEN @TotalCategorias = 6 THEN '✓' ELSE '✗' END;

-- Tipos de Movimiento
DECLARE @TotalTiposMovimiento INT;
SELECT @TotalTiposMovimiento = COUNT(*) FROM TiposMovimiento;
PRINT '   Tipos de Movimiento: ' + CAST(@TotalTiposMovimiento AS VARCHAR) + ' registros ' + 
    CASE WHEN @TotalTiposMovimiento = 6 THEN '✓' ELSE '✗' END;

PRINT '';

-- =============================================
-- PRUEBA 3: Verificar vistas
-- =============================================
PRINT '3. VERIFICANDO VISTAS...';
PRINT '';

DECLARE @VistasEsperadas TABLE (NombreVista VARCHAR(100));
INSERT INTO @VistasEsperadas VALUES 
    ('vw_ProductosStockBajo'),
    ('vw_ResumenInventario'),
    ('vw_HistorialMovimientos');

SELECT 
    ve.NombreVista,
    CASE WHEN v.name IS NOT NULL THEN '✓ OK' ELSE '✗ FALTA' END AS Estado
FROM @VistasEsperadas ve
LEFT JOIN sys.views v ON ve.NombreVista = v.name
ORDER BY ve.NombreVista;

PRINT '';

-- =============================================
-- PRUEBA 4: Verificar procedimientos almacenados
-- =============================================
PRINT '4. VERIFICANDO PROCEDIMIENTOS ALMACENADOS...';
PRINT '';

DECLARE @ProcedimientosEsperados TABLE (NombreProcedimiento VARCHAR(100));
INSERT INTO @ProcedimientosEsperados VALUES 
    ('sp_RegistrarMovimiento'),
    ('sp_ObtenerDashboard');

SELECT 
    pe.NombreProcedimiento,
    CASE WHEN p.name IS NOT NULL THEN '✓ OK' ELSE '✗ FALTA' END AS Estado
FROM @ProcedimientosEsperados pe
LEFT JOIN sys.procedures p ON pe.NombreProcedimiento = p.name
ORDER BY pe.NombreProcedimiento;

PRINT '';

-- =============================================
-- PRUEBA 5: Verificar triggers
-- =============================================
PRINT '5. VERIFICANDO TRIGGERS...';
PRINT '';

SELECT 
    t.name AS Trigger_Name,
    OBJECT_NAME(t.parent_id) AS Tabla,
    '✓ OK' AS Estado
FROM sys.triggers t
WHERE t.parent_class = 1 -- Solo triggers de tabla
ORDER BY t.name;

PRINT '';

-- =============================================
-- PRUEBA 6: Verificar índices
-- =============================================
PRINT '6. VERIFICANDO ÍNDICES...';
PRINT '';

SELECT 
    t.name AS Tabla,
    i.name AS Indice,
    '✓ OK' AS Estado
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name IS NOT NULL 
    AND i.type_desc = 'NONCLUSTERED'
ORDER BY t.name, i.name;

PRINT '';

-- =============================================
-- PRUEBA 7: Crear datos de prueba
-- =============================================
PRINT '7. CREANDO DATOS DE PRUEBA...';
PRINT '';

BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Crear proveedor de prueba
    IF NOT EXISTS (SELECT 1 FROM Proveedores WHERE nit = '12345678-9')
    BEGIN
        INSERT INTO Proveedores (nit, nombre_proveedor, telefono, email, direccion)
        VALUES ('12345678-9', 'Proveedor Test', '2222-3333', 'test@proveedor.com', 'Zona 10, Guatemala');
        PRINT '   ✓ Proveedor de prueba creado';
    END
    ELSE
        PRINT '   ℹ Proveedor de prueba ya existe';
    
    -- Crear producto de prueba
    IF NOT EXISTS (SELECT 1 FROM Productos WHERE sku = 'TEST-001')
    BEGIN
        INSERT INTO Productos (
            sku, codigo_barras, nombre_producto, descripcion,
            id_categoria, id_proveedor, precio_compra, precio_venta,
            stock_actual, stock_minimo, stock_maximo, ubicacion
        )
        VALUES (
            'TEST-001', '7501234567890', 'Producto de Prueba', 
            'Este es un producto de prueba para verificar el sistema',
            1, 1, 10.50, 15.00, 100, 20, 200, 'A-01'
        );
        PRINT '   ✓ Producto de prueba creado';
    END
    ELSE
        PRINT '   ℹ Producto de prueba ya existe';
    
    COMMIT TRANSACTION;
    PRINT '';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT '   ✗ Error al crear datos de prueba: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

-- =============================================
-- PRUEBA 8: Probar procedimiento sp_RegistrarMovimiento
-- =============================================
PRINT '8. PROBANDO PROCEDIMIENTO sp_RegistrarMovimiento...';
PRINT '';

BEGIN TRY
    -- Obtener IDs necesarios
    DECLARE @id_producto_test INT;
    DECLARE @id_usuario_test INT;
    DECLARE @id_proveedor_test INT;
    
    SELECT @id_producto_test = id_producto FROM Productos WHERE sku = 'TEST-001';
    SELECT @id_usuario_test = id_usuario FROM Usuarios WHERE username = 'admin';
    SELECT @id_proveedor_test = id_proveedor FROM Proveedores WHERE nit = '12345678-9';
    
    IF @id_producto_test IS NOT NULL
    BEGIN
        -- Registrar una entrada
        EXEC sp_RegistrarMovimiento 
            @id_producto = @id_producto_test,
            @id_tipo_movimiento = 1,  -- Entrada
            @cantidad = 50,
            @id_usuario = @id_usuario_test,
            @id_proveedor = @id_proveedor_test,
            @numero_documento = 'TEST-FAC-001',
            @observaciones = 'Movimiento de prueba - Entrada';
        
        PRINT '   ✓ Entrada registrada correctamente';
        
        -- Registrar una salida
        EXEC sp_RegistrarMovimiento 
            @id_producto = @id_producto_test,
            @id_tipo_movimiento = 2,  -- Salida
            @cantidad = 30,
            @id_usuario = @id_usuario_test,
            @numero_documento = 'TEST-VTA-001',
            @observaciones = 'Movimiento de prueba - Salida';
        
        PRINT '   Salida registrada correctamente';
        
        -- Verificar stock actualizado
        DECLARE @stock_actual INT;
        SELECT @stock_actual = stock_actual FROM Productos WHERE id_producto = @id_producto_test;
        PRINT '   Stock actual del producto: ' + CAST(@stock_actual AS VARCHAR) + ' unidades';
    END
    ELSE
        PRINT '   No se encontró producto de prueba';
    
    PRINT '';
    
END TRY
BEGIN CATCH
    PRINT '   Error al probar procedimiento: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

-- =============================================
-- PRUEBA 9: Probar procedimiento sp_ObtenerDashboard
-- =============================================
PRINT '9. PROBANDO PROCEDIMIENTO sp_ObtenerDashboard...';
PRINT '';

BEGIN TRY
    EXEC sp_ObtenerDashboard;
    PRINT '   Dashboard ejecutado correctamente';
    PRINT '';
END TRY
BEGIN CATCH
    PRINT '   Error al ejecutar dashboard: ' + ERROR_MESSAGE();
    PRINT '';
END CATCH

-- =============================================
-- PRUEBA 10: Verificar vistas con datos
-- =============================================
PRINT '10. VERIFICANDO VISTAS CON DATOS...';
PRINT '';

-- vw_ResumenInventario
DECLARE @ProductosEnVista INT;
SELECT @ProductosEnVista = COUNT(*) FROM vw_ResumenInventario;
PRINT '   vw_ResumenInventario: ' + CAST(@ProductosEnVista AS VARCHAR) + ' registros ✓';

-- vw_HistorialMovimientos
DECLARE @MovimientosEnVista INT;
SELECT @MovimientosEnVista = COUNT(*) FROM vw_HistorialMovimientos;
PRINT '   vw_HistorialMovimientos: ' + CAST(@MovimientosEnVista AS VARCHAR) + ' registros ✓';

-- vw_ProductosStockBajo
DECLARE @ProductosStockBajo INT;
SELECT @ProductosStockBajo = COUNT(*) FROM vw_ProductosStockBajo;
PRINT '   vw_ProductosStockBajo: ' + CAST(@ProductosStockBajo AS VARCHAR) + ' registros ✓';

PRINT '';

-- =============================================
-- PRUEBA 11: Verificar auditoría
-- =============================================
PRINT '11. VERIFICANDO SISTEMA DE AUDITORÍA...';
PRINT '';

DECLARE @RegistrosAuditoria INT;
SELECT @RegistrosAuditoria = COUNT(*) FROM Auditoria;

IF @RegistrosAuditoria > 0
    PRINT '   Sistema de auditoría funcionando: ' + CAST(@RegistrosAuditoria AS VARCHAR) + ' registros';
ELSE
    PRINT '   No hay registros de auditoría aún (normal en instalación nueva)';

PRINT '';

-- =============================================
-- PRUEBA 12: Verificar Foreign Keys
-- =============================================
PRINT '12. VERIFICANDO RELACIONES (FOREIGN KEYS)...';
PRINT '';

SELECT 
    OBJECT_NAME(fk.parent_object_id) AS Tabla,
    OBJECT_NAME(fk.referenced_object_id) AS Tabla_Referenciada,
    fk.name AS Nombre_FK,
    '✓ OK' AS Estado
FROM sys.foreign_keys fk
ORDER BY Tabla, Tabla_Referenciada;

PRINT '';

-- =============================================
-- RESUMEN FINAL
-- =============================================
PRINT '========================================';
PRINT 'RESUMEN DE PRUEBAS';
PRINT '========================================';
PRINT '';

-- Contar tablas
DECLARE @TotalTablas INT;
SELECT @TotalTablas = COUNT(*) FROM sys.tables 
WHERE name IN ('Roles', 'Usuarios', 'Categorias', 'Proveedores', 'Productos', 
               'TiposMovimiento', 'Movimientos', 'Auditoria', 'AlertasStock');

-- Contar vistas
DECLARE @TotalVistas INT;
SELECT @TotalVistas = COUNT(*) FROM sys.views 
WHERE name IN ('vw_ProductosStockBajo', 'vw_ResumenInventario', 'vw_HistorialMovimientos');

-- Contar procedimientos
DECLARE @TotalProcedimientos INT;
SELECT @TotalProcedimientos = COUNT(*) FROM sys.procedures 
WHERE name IN ('sp_RegistrarMovimiento', 'sp_ObtenerDashboard');

-- Contar triggers
DECLARE @TotalTriggers INT;
SELECT @TotalTriggers = COUNT(*) FROM sys.triggers WHERE parent_class = 1;

-- Contar foreign keys
DECLARE @TotalFKs INT;
SELECT @TotalFKs = COUNT(*) FROM sys.foreign_keys;

PRINT 'Tablas: ' + CAST(@TotalTablas AS VARCHAR) + '/9 ' + 
    CASE WHEN @TotalTablas = 9 THEN '✓' ELSE '✗' END;

PRINT 'Vistas: ' + CAST(@TotalVistas AS VARCHAR) + '/3 ' + 
    CASE WHEN @TotalVistas = 3 THEN '✓' ELSE '✗' END;

PRINT 'Procedimientos: ' + CAST(@TotalProcedimientos AS VARCHAR) + '/2 ' + 
    CASE WHEN @TotalProcedimientos = 2 THEN '✓' ELSE '✗' END;

PRINT 'Triggers: ' + CAST(@TotalTriggers AS VARCHAR) + ' ' + 
    CASE WHEN @TotalTriggers > 0 THEN '✓' ELSE 'ℹ' END;

PRINT 'Foreign Keys: ' + CAST(@TotalFKs AS VARCHAR) + ' ✓';

PRINT '';
PRINT 'Datos Iniciales:';
PRINT '   Roles: ' + CAST(@TotalRoles AS VARCHAR) + '/4 ' + 
    CASE WHEN @TotalRoles = 4 THEN '✓' ELSE '✗' END;
PRINT '   Usuarios: ' + CAST(@TotalUsuarios AS VARCHAR) + ' ' + 
    CASE WHEN @TotalUsuarios >= 1 THEN '✓' ELSE '✗' END;
PRINT '   Categorías: ' + CAST(@TotalCategorias AS VARCHAR) + '/6 ' + 
    CASE WHEN @TotalCategorias = 6 THEN '✓' ELSE '✗' END;
PRINT '   Tipos de Movimiento: ' + CAST(@TotalTiposMovimiento AS VARCHAR) + '/6 ' + 
    CASE WHEN @TotalTiposMovimiento = 6 THEN '✓' ELSE '✗' END;

PRINT '';
PRINT '========================================';

IF @TotalTablas = 9 AND @TotalVistas = 3 AND @TotalProcedimientos = 2 
   AND @TotalRoles = 4 AND @TotalCategorias = 6 AND @TotalTiposMovimiento = 6
BEGIN
    PRINT '¡TODAS LAS PRUEBAS PASARON!';
    PRINT '  La base de datos está correctamente instalada.';
END
ELSE
BEGIN
    PRINT ' ALGUNAS PRUEBAS FALLARON';
    PRINT '  Revisa los mensajes anteriores para más detalles.';
END

PRINT '========================================';
PRINT '';

-- Mostrar productos de ejemplo
PRINT 'PRODUCTOS DE PRUEBA CREADOS:';
PRINT '';

SELECT 
    p.sku,
    p.nombre_producto,
    p.stock_actual AS stock,
    p.precio_venta AS precio,
    pr.nombre_proveedor AS proveedor
FROM Productos p
LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor
WHERE p.sku LIKE 'TEST%';

PRINT '';
PRINT 'MOVIMIENTOS DE PRUEBA REGISTRADOS:';
PRINT '';

SELECT 
    m.fecha_movimiento AS fecha,
    p.nombre_producto AS producto,
    tm.nombre_tipo AS tipo,
    m.cantidad,
    m.stock_anterior,
    m.stock_nuevo
FROM Movimientos m
INNER JOIN Productos p ON m.id_producto = p.id_producto
INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
WHERE p.sku LIKE 'TEST%'
ORDER BY m.fecha_movimiento DESC;

PRINT '';
PRINT '========================================';
PRINT 'CREDENCIALES POR DEFECTO:';
PRINT '   Username: admin';
PRINT '   Password: admin123';
PRINT '   CAMBIAR ANTES DE USAR EN PRODUCCIÓN';
PRINT '========================================';
PRINT '';
PRINT 'Próximo paso: Desarrollar aplicación Flask';
PRINT '';

GO