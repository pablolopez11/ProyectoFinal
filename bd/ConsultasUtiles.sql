USE SGI_GuateMart;
GO

-- =============================================
-- SECCIÓN 1: GESTIÓN DE PRODUCTOS
-- =============================================

-- 1.1 Listar todos los productos activos con su información completa
SELECT 
    p.id_producto,
    p.sku,
    p.codigo_barras,
    p.nombre_producto,
    c.nombre_categoria,
    pr.nombre_proveedor,
    p.precio_compra,
    p.precio_venta,
    p.stock_actual,
    p.stock_minimo,
    p.stock_maximo,
    CASE 
        WHEN p.stock_actual = 0 THEN 'AGOTADO'
        WHEN p.stock_actual <= p.stock_minimo THEN 'BAJO'
        WHEN p.stock_actual >= p.stock_maximo THEN 'EXCESO'
        ELSE 'NORMAL'
    END AS estado_stock
FROM Productos p
LEFT JOIN Categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor
WHERE p.activo = 1
ORDER BY p.nombre_producto;

-- 1.2 Buscar producto por SKU
SELECT * FROM vw_ResumenInventario
WHERE sku = 'PROD-001';

-- 1.3 Buscar producto por código de barras
SELECT * FROM vw_ResumenInventario
WHERE codigo_barras = '7501234567890';

-- 1.4 Productos por categoría
SELECT 
    c.nombre_categoria,
    COUNT(*) AS total_productos,
    SUM(p.stock_actual) AS total_unidades,
    SUM(p.stock_actual * p.precio_compra) AS valor_inventario
FROM Productos p
INNER JOIN Categorias c ON p.id_categoria = c.id_categoria
WHERE p.activo = 1
GROUP BY c.nombre_categoria
ORDER BY valor_inventario DESC;

-- 1.5 Productos con mayor valor en inventario
SELECT TOP 10
    p.sku,
    p.nombre_producto,
    p.stock_actual,
    p.precio_compra,
    (p.stock_actual * p.precio_compra) AS valor_total
FROM Productos p
WHERE p.activo = 1 AND p.stock_actual > 0
ORDER BY valor_total DESC;

-- =============================================
-- SECCIÓN 2: CONTROL DE STOCK
-- =============================================

-- 2.1 Productos con stock bajo (usando vista)
SELECT * FROM vw_ProductosStockBajo
ORDER BY 
    CASE nivel_alerta
        WHEN 'AGOTADO' THEN 1
        WHEN 'CRÍTICO' THEN 2
        WHEN 'BAJO' THEN 3
    END,
    stock_actual;

-- 2.2 Productos agotados
SELECT 
    p.sku,
    p.nombre_producto,
    pr.nombre_proveedor,
    pr.telefono,
    pr.email
FROM Productos p
LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor
WHERE p.stock_actual = 0 AND p.activo = 1
ORDER BY p.nombre_producto;

-- 2.3 Productos con exceso de inventario (sobre el máximo)
SELECT 
    p.sku,
    p.nombre_producto,
    p.stock_actual,
    p.stock_maximo,
    (p.stock_actual - p.stock_maximo) AS exceso,
    (p.stock_actual * p.precio_compra) AS valor_exceso
FROM Productos p
WHERE p.stock_actual > p.stock_maximo AND p.activo = 1
ORDER BY exceso DESC;

-- 2.4 Resumen de stock por estado
SELECT 
    CASE 
        WHEN stock_actual = 0 THEN 'AGOTADO'
        WHEN stock_actual <= stock_minimo THEN 'BAJO'
        WHEN stock_actual >= stock_maximo THEN 'EXCESO'
        ELSE 'NORMAL'
    END AS estado,
    COUNT(*) AS cantidad_productos,
    SUM(stock_actual * precio_compra) AS valor_total
FROM Productos
WHERE activo = 1
GROUP BY 
    CASE 
        WHEN stock_actual = 0 THEN 'AGOTADO'
        WHEN stock_actual <= stock_minimo THEN 'BAJO'
        WHEN stock_actual >= stock_maximo THEN 'EXCESO'
        ELSE 'NORMAL'
    END;

-- =============================================
-- SECCIÓN 3: MOVIMIENTOS DE INVENTARIO
-- =============================================

-- 3.1 Historial de movimientos recientes (últimos 30 días)
SELECT * FROM vw_HistorialMovimientos
WHERE fecha_movimiento >= DATEADD(DAY, -30, GETDATE())
ORDER BY fecha_movimiento DESC;

-- 3.2 Movimientos de un producto específico
SELECT * FROM vw_HistorialMovimientos
WHERE sku = 'PROD-001'
ORDER BY fecha_movimiento DESC;

-- 3.3 Entradas del mes actual
SELECT 
    p.nombre_producto,
    m.cantidad,
    pr.nombre_proveedor,
    m.numero_documento,
    m.fecha_movimiento
FROM Movimientos m
INNER JOIN Productos p ON m.id_producto = p.id_producto
INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
LEFT JOIN Proveedores pr ON m.id_proveedor = pr.id_proveedor
WHERE tm.afecta_stock = 'SUMA'
    AND MONTH(m.fecha_movimiento) = MONTH(GETDATE())
    AND YEAR(m.fecha_movimiento) = YEAR(GETDATE())
ORDER BY m.fecha_movimiento DESC;

-- 3.4 Salidas del mes actual
SELECT 
    p.nombre_producto,
    m.cantidad,
    m.fecha_movimiento,
    u.nombre_completo AS usuario
FROM Movimientos m
INNER JOIN Productos p ON m.id_producto = p.id_producto
INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
INNER JOIN Usuarios u ON m.id_usuario = u.id_usuario
WHERE tm.afecta_stock = 'RESTA'
    AND MONTH(m.fecha_movimiento) = MONTH(GETDATE())
    AND YEAR(m.fecha_movimiento) = YEAR(GETDATE())
ORDER BY m.fecha_movimiento DESC;

-- 3.5 Total de movimientos por tipo
SELECT 
    tm.nombre_tipo,
    COUNT(*) AS total_movimientos,
    SUM(m.cantidad) AS total_unidades
FROM Movimientos m
INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
WHERE m.fecha_movimiento >= DATEADD(MONTH, -1, GETDATE())
GROUP BY tm.nombre_tipo
ORDER BY total_movimientos DESC;

-- =============================================
-- SECCIÓN 4: PROVEEDORES
-- =============================================

-- 4.1 Listado de proveedores activos
SELECT 
    nit,
    nombre_proveedor,
    nombre_contacto,
    telefono,
    email,
    direccion
FROM Proveedores
WHERE activo = 1
ORDER BY nombre_proveedor;

-- 4.2 Productos por proveedor
SELECT 
    pr.nombre_proveedor,
    COUNT(p.id_producto) AS total_productos,
    SUM(p.stock_actual) AS total_unidades,
    SUM(p.stock_actual * p.precio_compra) AS valor_inventario
FROM Proveedores pr
LEFT JOIN Productos p ON pr.id_proveedor = p.id_proveedor
WHERE pr.activo = 1 AND (p.activo = 1 OR p.activo IS NULL)
GROUP BY pr.nombre_proveedor
ORDER BY valor_inventario DESC;

-- 4.3 Historial de compras por proveedor (últimos 3 meses)
SELECT 
    pr.nombre_proveedor,
    COUNT(m.id_movimiento) AS total_compras,
    SUM(m.cantidad) AS total_unidades,
    SUM(m.cantidad * p.precio_compra) AS valor_total
FROM Movimientos m
INNER JOIN Productos p ON m.id_producto = p.id_producto
INNER JOIN Proveedores pr ON m.id_proveedor = pr.id_proveedor
INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
WHERE tm.nombre_tipo = 'Entrada'
    AND m.fecha_movimiento >= DATEADD(MONTH, -3, GETDATE())
GROUP BY pr.nombre_proveedor
ORDER BY valor_total DESC;

-- =============================================
-- SECCIÓN 5: ALERTAS
-- =============================================

-- 5.1 Alertas pendientes
SELECT 
    a.id_alerta,
    p.sku,
    p.nombre_producto,
    a.tipo_alerta,
    a.stock_actual,
    a.stock_minimo,
    a.mensaje,
    a.fecha_generacion
FROM AlertasStock a
INNER JOIN Productos p ON a.id_producto = p.id_producto
WHERE a.estado = 'PENDIENTE'
ORDER BY 
    CASE a.tipo_alerta
        WHEN 'STOCK_CRITICO' THEN 1
        WHEN 'STOCK_MINIMO' THEN 2
    END,
    a.fecha_generacion;

-- 5.2 Alertas resueltas (últimos 30 días)
SELECT 
    a.id_alerta,
    p.nombre_producto,
    a.tipo_alerta,
    a.fecha_generacion,
    a.fecha_resolucion,
    u.nombre_completo AS resuelto_por
FROM AlertasStock a
INNER JOIN Productos p ON a.id_producto = p.id_producto
LEFT JOIN Usuarios u ON a.id_usuario_resolucion = u.id_usuario
WHERE a.estado = 'RESUELTA'
    AND a.fecha_resolucion >= DATEADD(DAY, -30, GETDATE())
ORDER BY a.fecha_resolucion DESC;

-- 5.3 Resolver una alerta
UPDATE AlertasStock
SET estado = 'RESUELTA',
    fecha_resolucion = GETDATE(),
    id_usuario_resolucion = 1  -- ID del usuario que resuelve
WHERE id_alerta = 1;

-- =============================================
-- SECCIÓN 6: REPORTES Y ESTADÍSTICAS
-- =============================================

-- 6.1 Dashboard general (usar procedimiento almacenado)
EXEC sp_ObtenerDashboard;

-- 6.2 Productos más vendidos (últimos 30 días)
SELECT TOP 10
    p.sku,
    p.nombre_producto,
    SUM(m.cantidad) AS total_vendido,
    SUM(m.cantidad * p.precio_venta) AS ingresos_estimados
FROM Movimientos m
INNER JOIN Productos p ON m.id_producto = p.id_producto
INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
WHERE tm.afecta_stock = 'RESTA'
    AND m.fecha_movimiento >= DATEADD(DAY, -30, GETDATE())
GROUP BY p.sku, p.nombre_producto
ORDER BY total_vendido DESC;

-- 6.3 Valor total del inventario
SELECT 
    COUNT(*) AS total_productos,
    SUM(stock_actual) AS total_unidades,
    SUM(stock_actual * precio_compra) AS valor_compra,
    SUM(stock_actual * precio_venta) AS valor_venta,
    SUM(stock_actual * (precio_venta - precio_compra)) AS utilidad_potencial,
    AVG(precio_venta - precio_compra) AS margen_promedio
FROM Productos
WHERE activo = 1;

-- 6.4 Rotación de inventario (productos más/menos movidos)
SELECT 
    p.sku,
    p.nombre_producto,
    p.stock_actual,
    COUNT(m.id_movimiento) AS total_movimientos,
    SUM(CASE WHEN tm.afecta_stock = 'SUMA' THEN m.cantidad ELSE 0 END) AS total_entradas,
    SUM(CASE WHEN tm.afecta_stock = 'RESTA' THEN m.cantidad ELSE 0 END) AS total_salidas
FROM Productos p
LEFT JOIN Movimientos m ON p.id_producto = m.id_producto
LEFT JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
WHERE p.activo = 1
    AND (m.fecha_movimiento >= DATEADD(MONTH, -3, GETDATE()) OR m.fecha_movimiento IS NULL)
GROUP BY p.sku, p.nombre_producto, p.stock_actual
ORDER BY total_movimientos DESC;

-- 6.5 Reporte de ventas por categoría (últimos 30 días)
SELECT 
    c.nombre_categoria,
    COUNT(DISTINCT p.id_producto) AS productos_vendidos,
    SUM(m.cantidad) AS total_unidades,
    SUM(m.cantidad * p.precio_venta) AS ingresos_estimados
FROM Movimientos m
INNER JOIN Productos p ON m.id_producto = p.id_producto
INNER JOIN Categorias c ON p.id_categoria = c.id_categoria
INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
WHERE tm.afecta_stock = 'RESTA'
    AND m.fecha_movimiento >= DATEADD(DAY, -30, GETDATE())
GROUP BY c.nombre_categoria
ORDER BY ingresos_estimados DESC;

-- 6.6 Productos sin movimiento (últimos 60 días)
SELECT 
    p.sku,
    p.nombre_producto,
    p.stock_actual,
    (p.stock_actual * p.precio_compra) AS valor_inmovilizado,
    MAX(m.fecha_movimiento) AS ultimo_movimiento
FROM Productos p
LEFT JOIN Movimientos m ON p.id_producto = m.id_producto
WHERE p.activo = 1
GROUP BY p.sku, p.nombre_producto, p.stock_actual, p.precio_compra
HAVING MAX(m.fecha_movimiento) < DATEADD(DAY, -60, GETDATE())
    OR MAX(m.fecha_movimiento) IS NULL
ORDER BY valor_inmovilizado DESC;

-- 6.7 Análisis de rentabilidad por producto
SELECT 
    p.sku,
    p.nombre_producto,
    p.precio_compra,
    p.precio_venta,
    (p.precio_venta - p.precio_compra) AS margen_unitario,
    CASE 
        WHEN p.precio_compra > 0 
        THEN ROUND(((p.precio_venta - p.precio_compra) / p.precio_compra * 100), 2)
        ELSE 0 
    END AS porcentaje_margen,
    p.stock_actual,
    (p.stock_actual * (p.precio_venta - p.precio_compra)) AS utilidad_potencial
FROM Productos p
WHERE p.activo = 1 AND p.precio_compra > 0
ORDER BY porcentaje_margen DESC;

-- =============================================
-- SECCIÓN 7: AUDITORÍA
-- =============================================

-- 7.1 Últimas operaciones registradas
SELECT TOP 50
    a.fecha_operacion,
    a.tabla_afectada,
    a.operacion,
    u.nombre_completo AS usuario,
    a.detalles
FROM Auditoria a
LEFT JOIN Usuarios u ON a.id_usuario = u.id_usuario
ORDER BY a.fecha_operacion DESC;

-- 7.2 Auditoría por usuario
SELECT 
    u.nombre_completo,
    a.tabla_afectada,
    a.operacion,
    COUNT(*) AS total_operaciones,
    MAX(a.fecha_operacion) AS ultima_operacion
FROM Auditoria a
INNER JOIN Usuarios u ON a.id_usuario = u.id_usuario
GROUP BY u.nombre_completo, a.tabla_afectada, a.operacion
ORDER BY u.nombre_completo, total_operaciones DESC;

-- 7.3 Auditoría de productos (últimas modificaciones)
SELECT 
    a.fecha_operacion,
    u.nombre_completo AS usuario,
    a.datos_anteriores,
    a.datos_nuevos
FROM Auditoria a
INNER JOIN Usuarios u ON a.id_usuario = u.id_usuario
WHERE a.tabla_afectada = 'Productos'
ORDER BY a.fecha_operacion DESC;

-- =============================================
-- SECCIÓN 8: USUARIOS Y SEGURIDAD
-- =============================================

-- 8.1 Listado de usuarios activos
SELECT 
    u.username,
    u.nombre_completo,
    u.email,
    r.nombre_rol,
    u.ultimo_acceso,
    u.fecha_creacion
FROM Usuarios u
INNER JOIN Roles r ON u.id_rol = r.id_rol
WHERE u.activo = 1
ORDER BY u.nombre_completo;

-- 8.2 Actividad de usuarios (últimos 7 días)
SELECT 
    u.nombre_completo,
    COUNT(m.id_movimiento) AS movimientos_registrados,
    COUNT(a.id_auditoria) AS total_operaciones,
    MAX(m.fecha_movimiento) AS ultimo_movimiento
FROM Usuarios u
LEFT JOIN Movimientos m ON u.id_usuario = m.id_usuario 
    AND m.fecha_movimiento >= DATEADD(DAY, -7, GETDATE())
LEFT JOIN Auditoria a ON u.id_usuario = a.id_usuario 
    AND a.fecha_operacion >= DATEADD(DAY, -7, GETDATE())
WHERE u.activo = 1
GROUP BY u.nombre_completo
ORDER BY total_operaciones DESC;

-- =============================================
-- SECCIÓN 9: MANTENIMIENTO
-- =============================================

-- 9.1 Limpiar alertas resueltas antiguas (más de 90 días)
DELETE FROM AlertasStock
WHERE estado = 'RESUELTA'
    AND fecha_resolucion < DATEADD(DAY, -90, GETDATE());

-- 9.2 Limpiar auditoría antigua (más de 6 meses)
DELETE FROM Auditoria
WHERE fecha_operacion < DATEADD(MONTH, -6, GETDATE());

-- 9.3 Desactivar productos sin stock ni movimientos (más de 1 año)
UPDATE Productos
SET activo = 0
WHERE stock_actual = 0
    AND id_producto NOT IN (
        SELECT DISTINCT id_producto 
        FROM Movimientos 
        WHERE fecha_movimiento >= DATEADD(YEAR, -1, GETDATE())
    );

-- 9.4 Estadísticas de la base de datos
SELECT 
    t.name AS tabla,
    SUM(p.rows) AS total_registros
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
    AND t.name IN ('Productos', 'Movimientos', 'Auditoria', 'Usuarios', 'Proveedores', 'AlertasStock')
GROUP BY t.name
ORDER BY total_registros DESC;

-- =============================================
-- SECCIÓN 10: EJEMPLOS DE USO DEL SP
-- =============================================

-- 10.1 Registrar entrada de mercadería
EXEC sp_RegistrarMovimiento 
    @id_producto = 1,
    @id_tipo_movimiento = 1,  -- Entrada
    @cantidad = 100,
    @id_usuario = 1,
    @id_proveedor = 1,
    @numero_documento = 'FAC-12345',
    @observaciones = 'Compra mensual de productos';

-- 10.2 Registrar salida de mercadería
EXEC sp_RegistrarMovimiento 
    @id_producto = 1,
    @id_tipo_movimiento = 2,  -- Salida
    @cantidad = 50,
    @id_usuario = 1,
    @numero_documento = 'VTA-98765',
    @observaciones = 'Venta a cliente';

-- 10.3 Ajuste de inventario positivo
EXEC sp_RegistrarMovimiento 
    @id_producto = 1,
    @id_tipo_movimiento = 3,  -- Ajuste Positivo
    @cantidad = 10,
    @id_usuario = 1,
    @observaciones = 'Corrección por inventario físico';

-- 10.4 Ajuste de inventario negativo
EXEC sp_RegistrarMovimiento 
    @id_producto = 1,
    @id_tipo_movimiento = 4,  -- Ajuste Negativo
    @cantidad = 5,
    @id_usuario = 1,
    @observaciones = 'Merma por producto dañado';

GO

PRINT 'Consultas útiles cargadas correctamente';
PRINT 'Usa estas consultas como referencia para tu aplicación Python/Flask';