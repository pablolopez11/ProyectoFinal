-- =============================================
-- Sistema de Gestión de Inventarios (SGI-GuateMart)
-- Base de Datos - SQL Server Express
-- Versión Corregida (sin tipo TEXT)
-- =============================================

USE master;
GO

-- Crear la base de datos si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'SGI_GuateMart')
BEGIN
    CREATE DATABASE SGI_GuateMart;
END
GO

USE SGI_GuateMart;
GO

-- =============================================
-- TABLA: Roles
-- Gestión de roles del sistema
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
BEGIN
    CREATE TABLE Roles (
        id_rol INT IDENTITY(1,1) PRIMARY KEY,
        nombre_rol VARCHAR(50) NOT NULL UNIQUE,
        descripcion VARCHAR(255),
        activo BIT DEFAULT 1,
        fecha_creacion DATETIME DEFAULT GETDATE()
    );
END
GO

-- =============================================
-- TABLA: Usuarios
-- Gestión de usuarios del sistema con autenticación
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Usuarios')
BEGIN
    CREATE TABLE Usuarios (
        id_usuario INT IDENTITY(1,1) PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        nombre_completo VARCHAR(100) NOT NULL,
        email VARCHAR(100),
        id_rol INT NOT NULL,
        activo BIT DEFAULT 1,
        ultimo_acceso DATETIME,
        fecha_creacion DATETIME DEFAULT GETDATE(),
        fecha_modificacion DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (id_rol) REFERENCES Roles(id_rol)
    );
END
GO

-- =============================================
-- TABLA: Categorias
-- Clasificación de productos
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categorias')
BEGIN
    CREATE TABLE Categorias (
        id_categoria INT IDENTITY(1,1) PRIMARY KEY,
        nombre_categoria VARCHAR(100) NOT NULL UNIQUE,
        descripcion VARCHAR(255),
        activo BIT DEFAULT 1,
        fecha_creacion DATETIME DEFAULT GETDATE()
    );
END
GO

-- =============================================
-- TABLA: Proveedores
-- Gestión de proveedores
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Proveedores')
BEGIN
    CREATE TABLE Proveedores (
        id_proveedor INT IDENTITY(1,1) PRIMARY KEY,
        nit VARCHAR(20) NOT NULL UNIQUE,
        nombre_proveedor VARCHAR(150) NOT NULL,
        nombre_contacto VARCHAR(100),
        telefono VARCHAR(20),
        email VARCHAR(100),
        direccion VARCHAR(255),
        activo BIT DEFAULT 1,
        fecha_creacion DATETIME DEFAULT GETDATE(),
        fecha_modificacion DATETIME DEFAULT GETDATE()
    );
END
GO

-- =============================================
-- TABLA: Productos
-- Registro de productos con control de stock
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Productos')
BEGIN
    CREATE TABLE Productos (
        id_producto INT IDENTITY(1,1) PRIMARY KEY,
        sku VARCHAR(50) NOT NULL UNIQUE,
        codigo_barras VARCHAR(50),
        nombre_producto VARCHAR(150) NOT NULL,
        descripcion VARCHAR(MAX),  -- Cambiado de TEXT a VARCHAR(MAX)
        id_categoria INT,
        id_proveedor INT,
        precio_compra DECIMAL(10,2) DEFAULT 0,
        precio_venta DECIMAL(10,2) DEFAULT 0,
        stock_actual INT DEFAULT 0,
        stock_minimo INT DEFAULT 0,
        stock_maximo INT DEFAULT 0,
        ubicacion VARCHAR(50),
        activo BIT DEFAULT 1,
        fecha_creacion DATETIME DEFAULT GETDATE(),
        fecha_modificacion DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (id_categoria) REFERENCES Categorias(id_categoria),
        FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
        CONSTRAINT CK_Stock_Positivo CHECK (stock_actual >= 0),
        CONSTRAINT CK_Stock_Minimo CHECK (stock_minimo >= 0),
        CONSTRAINT CK_Precios_Positivos CHECK (precio_compra >= 0 AND precio_venta >= 0)
    );
END
GO

-- =============================================
-- TABLA: TiposMovimiento
-- Tipos de movimientos de inventario
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TiposMovimiento')
BEGIN
    CREATE TABLE TiposMovimiento (
        id_tipo_movimiento INT IDENTITY(1,1) PRIMARY KEY,
        nombre_tipo VARCHAR(50) NOT NULL UNIQUE,
        afecta_stock VARCHAR(10) NOT NULL, -- 'SUMA', 'RESTA', 'AJUSTE'
        descripcion VARCHAR(255),
        activo BIT DEFAULT 1
    );
END
GO

-- =============================================
-- TABLA: Movimientos
-- Registro de movimientos de inventario
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Movimientos')
BEGIN
    CREATE TABLE Movimientos (
        id_movimiento INT IDENTITY(1,1) PRIMARY KEY,
        id_producto INT NOT NULL,
        id_tipo_movimiento INT NOT NULL,
        cantidad INT NOT NULL,
        stock_anterior INT NOT NULL,
        stock_nuevo INT NOT NULL,
        id_usuario INT NOT NULL,
        id_proveedor INT,
        numero_documento VARCHAR(50),
        observaciones VARCHAR(MAX),  -- Cambiado de TEXT a VARCHAR(MAX)
        fecha_movimiento DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (id_producto) REFERENCES Productos(id_producto),
        FOREIGN KEY (id_tipo_movimiento) REFERENCES TiposMovimiento(id_tipo_movimiento),
        FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario),
        FOREIGN KEY (id_proveedor) REFERENCES Proveedores(id_proveedor),
        CONSTRAINT CK_Cantidad_Positiva CHECK (cantidad > 0)
    );
END
GO

-- =============================================
-- TABLA: Auditoria
-- Registro de auditoría del sistema
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Auditoria')
BEGIN
    CREATE TABLE Auditoria (
        id_auditoria INT IDENTITY(1,1) PRIMARY KEY,
        tabla_afectada VARCHAR(50) NOT NULL,
        operacion VARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
        id_registro INT,
        id_usuario INT,
        datos_anteriores VARCHAR(MAX),  -- Cambiado de TEXT a VARCHAR(MAX)
        datos_nuevos VARCHAR(MAX),      -- Cambiado de TEXT a VARCHAR(MAX)
        fecha_operacion DATETIME DEFAULT GETDATE(),
        ip_address VARCHAR(50),
        detalles VARCHAR(MAX),          -- Cambiado de TEXT a VARCHAR(MAX)
        FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
    );
END
GO

-- =============================================
-- TABLA: AlertasStock
-- Registro de alertas de stock bajo
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AlertasStock')
BEGIN
    CREATE TABLE AlertasStock (
        id_alerta INT IDENTITY(1,1) PRIMARY KEY,
        id_producto INT NOT NULL,
        tipo_alerta VARCHAR(50) NOT NULL, -- 'STOCK_MINIMO', 'STOCK_CRITICO'
        stock_actual INT NOT NULL,
        stock_minimo INT NOT NULL,
        mensaje VARCHAR(MAX),  -- Cambiado de TEXT a VARCHAR(MAX)
        estado VARCHAR(20) DEFAULT 'PENDIENTE', -- PENDIENTE, RESUELTA
        fecha_generacion DATETIME DEFAULT GETDATE(),
        fecha_resolucion DATETIME,
        id_usuario_resolucion INT,
        FOREIGN KEY (id_producto) REFERENCES Productos(id_producto),
        FOREIGN KEY (id_usuario_resolucion) REFERENCES Usuarios(id_usuario)
    );
END
GO

-- =============================================
-- ÍNDICES para optimización
-- =============================================

-- Índices en Usuarios
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Usuarios_Username')
    CREATE NONCLUSTERED INDEX IX_Usuarios_Username ON Usuarios(username);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Usuarios_Activo')
    CREATE NONCLUSTERED INDEX IX_Usuarios_Activo ON Usuarios(activo);

-- Índices en Productos
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Productos_SKU')
    CREATE NONCLUSTERED INDEX IX_Productos_SKU ON Productos(sku);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Productos_CodigoBarras')
    CREATE NONCLUSTERED INDEX IX_Productos_CodigoBarras ON Productos(codigo_barras);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Productos_Activo')
    CREATE NONCLUSTERED INDEX IX_Productos_Activo ON Productos(activo);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Productos_Categoria')
    CREATE NONCLUSTERED INDEX IX_Productos_Categoria ON Productos(id_categoria);

-- Índices en Movimientos
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Movimientos_Producto')
    CREATE NONCLUSTERED INDEX IX_Movimientos_Producto ON Movimientos(id_producto);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Movimientos_Fecha')
    CREATE NONCLUSTERED INDEX IX_Movimientos_Fecha ON Movimientos(fecha_movimiento);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Movimientos_Usuario')
    CREATE NONCLUSTERED INDEX IX_Movimientos_Usuario ON Movimientos(id_usuario);

-- Índices en Auditoría
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Auditoria_Tabla')
    CREATE NONCLUSTERED INDEX IX_Auditoria_Tabla ON Auditoria(tabla_afectada);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Auditoria_Fecha')
    CREATE NONCLUSTERED INDEX IX_Auditoria_Fecha ON Auditoria(fecha_operacion);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Auditoria_Usuario')
    CREATE NONCLUSTERED INDEX IX_Auditoria_Usuario ON Auditoria(id_usuario);

GO

-- =============================================
-- INSERCIÓN DE DATOS INICIALES
-- =============================================

-- Roles iniciales
IF NOT EXISTS (SELECT * FROM Roles)
BEGIN
    INSERT INTO Roles (nombre_rol, descripcion) VALUES
    ('Administrador', 'Acceso completo al sistema'),
    ('Gerente', 'Gestión de inventario y reportes'),
    ('Almacenista', 'Registro de movimientos de inventario'),
    ('Consulta', 'Solo visualización de información');
END
GO

-- Usuario administrador por defecto
-- Password: admin123 (deberá cambiarse en producción)
IF NOT EXISTS (SELECT * FROM Usuarios WHERE username = 'admin')
BEGIN
    INSERT INTO Usuarios (username, password_hash, nombre_completo, email, id_rol, activo)
    VALUES ('admin', 'admin123', 'Administrador del Sistema', 'admin@guatemart.com', 1, 1);
END
GO

-- Tipos de Movimiento
IF NOT EXISTS (SELECT * FROM TiposMovimiento)
BEGIN
    INSERT INTO TiposMovimiento (nombre_tipo, afecta_stock, descripcion) VALUES
    ('Entrada', 'SUMA', 'Entrada de mercadería al inventario'),
    ('Salida', 'RESTA', 'Salida de mercadería del inventario'),
    ('Ajuste Positivo', 'SUMA', 'Ajuste por inventario físico (incremento)'),
    ('Ajuste Negativo', 'RESTA', 'Ajuste por inventario físico (disminución)'),
    ('Devolución Entrada', 'RESTA', 'Devolución a proveedor'),
    ('Devolución Salida', 'SUMA', 'Devolución de cliente');
END
GO

-- Categorías de ejemplo
IF NOT EXISTS (SELECT * FROM Categorias)
BEGIN
    INSERT INTO Categorias (nombre_categoria, descripcion) VALUES
    ('Alimentos', 'Productos alimenticios'),
    ('Bebidas', 'Bebidas y líquidos'),
    ('Limpieza', 'Productos de limpieza'),
    ('Cuidado Personal', 'Productos de higiene personal'),
    ('Electrónica', 'Dispositivos electrónicos'),
    ('Hogar', 'Artículos para el hogar');
END
GO

-- =============================================
-- VISTAS ÚTILES
-- =============================================

-- Vista: Productos con alertas de stock
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ProductosStockBajo')
    DROP VIEW vw_ProductosStockBajo;
GO

CREATE VIEW vw_ProductosStockBajo AS
SELECT 
    p.id_producto,
    p.sku,
    p.nombre_producto,
    p.stock_actual,
    p.stock_minimo,
    p.stock_maximo,
    c.nombre_categoria,
    pr.nombre_proveedor,
    CASE 
        WHEN p.stock_actual <= 0 THEN 'AGOTADO'
        WHEN p.stock_actual <= (p.stock_minimo * 0.5) THEN 'CRÍTICO'
        WHEN p.stock_actual <= p.stock_minimo THEN 'BAJO'
    END AS nivel_alerta
FROM Productos p
LEFT JOIN Categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor
WHERE p.stock_actual <= p.stock_minimo AND p.activo = 1;
GO

-- Vista: Resumen de inventario
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ResumenInventario')
    DROP VIEW vw_ResumenInventario;
GO

CREATE VIEW vw_ResumenInventario AS
SELECT 
    p.id_producto,
    p.sku,
    p.codigo_barras,
    p.nombre_producto,
    p.descripcion,
    c.nombre_categoria,
    pr.nombre_proveedor,
    p.precio_compra,
    p.precio_venta,
    p.stock_actual,
    p.stock_minimo,
    p.stock_maximo,
    p.ubicacion,
    (p.stock_actual * p.precio_compra) AS valor_inventario,
    p.activo,
    p.fecha_creacion,
    p.fecha_modificacion
FROM Productos p
LEFT JOIN Categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN Proveedores pr ON p.id_proveedor = pr.id_proveedor;
GO

-- Vista: Historial de movimientos completo
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_HistorialMovimientos')
    DROP VIEW vw_HistorialMovimientos;
GO

CREATE VIEW vw_HistorialMovimientos AS
SELECT 
    m.id_movimiento,
    m.fecha_movimiento,
    p.sku,
    p.nombre_producto,
    tm.nombre_tipo AS tipo_movimiento,
    m.cantidad,
    m.stock_anterior,
    m.stock_nuevo,
    u.nombre_completo AS usuario,
    pr.nombre_proveedor,
    m.numero_documento,
    m.observaciones
FROM Movimientos m
INNER JOIN Productos p ON m.id_producto = p.id_producto
INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
INNER JOIN Usuarios u ON m.id_usuario = u.id_usuario
LEFT JOIN Proveedores pr ON m.id_proveedor = pr.id_proveedor;
GO

-- =============================================
-- PROCEDIMIENTOS ALMACENADOS
-- =============================================

-- Procedimiento: Registrar movimiento de inventario
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_RegistrarMovimiento')
    DROP PROCEDURE sp_RegistrarMovimiento;
GO

CREATE PROCEDURE sp_RegistrarMovimiento
    @id_producto INT,
    @id_tipo_movimiento INT,
    @cantidad INT,
    @id_usuario INT,
    @id_proveedor INT = NULL,
    @numero_documento VARCHAR(50) = NULL,
    @observaciones VARCHAR(MAX) = NULL  -- Cambiado de TEXT a VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @stock_anterior INT;
        DECLARE @stock_nuevo INT;
        DECLARE @afecta_stock VARCHAR(10);
        
        -- Obtener stock actual
        SELECT @stock_anterior = stock_actual FROM Productos WHERE id_producto = @id_producto;
        
        -- Obtener cómo afecta el movimiento
        SELECT @afecta_stock = afecta_stock FROM TiposMovimiento WHERE id_tipo_movimiento = @id_tipo_movimiento;
        
        -- Calcular nuevo stock
        IF @afecta_stock = 'SUMA'
            SET @stock_nuevo = @stock_anterior + @cantidad;
        ELSE IF @afecta_stock = 'RESTA'
            SET @stock_nuevo = @stock_anterior - @cantidad;
        ELSE
            SET @stock_nuevo = @cantidad; -- AJUSTE directo
        
        -- Validar que no quede negativo
        IF @stock_nuevo < 0
        BEGIN
            RAISERROR('No hay suficiente stock para realizar esta operación', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Registrar movimiento
        INSERT INTO Movimientos (
            id_producto, id_tipo_movimiento, cantidad, stock_anterior, 
            stock_nuevo, id_usuario, id_proveedor, numero_documento, observaciones
        )
        VALUES (
            @id_producto, @id_tipo_movimiento, @cantidad, @stock_anterior,
            @stock_nuevo, @id_usuario, @id_proveedor, @numero_documento, @observaciones
        );
        
        -- Actualizar stock del producto
        UPDATE Productos 
        SET stock_actual = @stock_nuevo,
            fecha_modificacion = GETDATE()
        WHERE id_producto = @id_producto;
        
        -- Verificar si se debe generar alerta de stock
        DECLARE @stock_minimo INT;
        SELECT @stock_minimo = stock_minimo FROM Productos WHERE id_producto = @id_producto;
        
        IF @stock_nuevo <= @stock_minimo
        BEGIN
            DECLARE @tipo_alerta VARCHAR(50);
            DECLARE @mensaje VARCHAR(MAX);  -- Cambiado de TEXT a VARCHAR(MAX)
            
            IF @stock_nuevo = 0
            BEGIN
                SET @tipo_alerta = 'STOCK_CRITICO';
                SET @mensaje = 'Producto agotado';
            END
            ELSE IF @stock_nuevo <= (@stock_minimo * 0.5)
            BEGIN
                SET @tipo_alerta = 'STOCK_CRITICO';
                SET @mensaje = 'Stock crítico, por debajo del 50% del mínimo';
            END
            ELSE
            BEGIN
                SET @tipo_alerta = 'STOCK_MINIMO';
                SET @mensaje = 'Stock alcanzó el nivel mínimo';
            END
            
            -- Insertar alerta si no existe una pendiente
            IF NOT EXISTS (
                SELECT 1 FROM AlertasStock 
                WHERE id_producto = @id_producto 
                AND estado = 'PENDIENTE'
            )
            BEGIN
                INSERT INTO AlertasStock (
                    id_producto, tipo_alerta, stock_actual, 
                    stock_minimo, mensaje, estado
                )
                VALUES (
                    @id_producto, @tipo_alerta, @stock_nuevo,
                    @stock_minimo, @mensaje, 'PENDIENTE'
                );
            END
        END
        
        COMMIT TRANSACTION;
        SELECT 'Movimiento registrado exitosamente' AS Resultado;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- Procedimiento: Obtener dashboard estadístico
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_ObtenerDashboard')
    DROP PROCEDURE sp_ObtenerDashboard;
GO

CREATE PROCEDURE sp_ObtenerDashboard
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Resumen general
    SELECT 
        COUNT(*) AS total_productos,
        SUM(stock_actual) AS total_items_inventario,
        SUM(stock_actual * precio_compra) AS valor_total_inventario,
        COUNT(CASE WHEN stock_actual <= stock_minimo THEN 1 END) AS productos_stock_bajo
    FROM Productos
    WHERE activo = 1;
    
    -- Productos más vendidos (últimos 30 días)
    SELECT TOP 10
        p.nombre_producto,
        SUM(m.cantidad) AS total_salidas
    FROM Movimientos m
    INNER JOIN Productos p ON m.id_producto = p.id_producto
    INNER JOIN TiposMovimiento tm ON m.id_tipo_movimiento = tm.id_tipo_movimiento
    WHERE tm.afecta_stock = 'RESTA'
        AND m.fecha_movimiento >= DATEADD(DAY, -30, GETDATE())
    GROUP BY p.nombre_producto
    ORDER BY total_salidas DESC;
    
    -- Alertas pendientes
    SELECT COUNT(*) AS alertas_pendientes
    FROM AlertasStock
    WHERE estado = 'PENDIENTE';
    
    -- Movimientos por día (últimos 7 días)
    SELECT 
        CAST(fecha_movimiento AS DATE) AS fecha,
        COUNT(*) AS total_movimientos
    FROM Movimientos
    WHERE fecha_movimiento >= DATEADD(DAY, -7, GETDATE())
    GROUP BY CAST(fecha_movimiento AS DATE)
    ORDER BY fecha DESC;
END
GO

-- =============================================
-- TRIGGERS PARA AUDITORÍA AUTOMÁTICA
-- =============================================

-- Trigger: Auditoría de Productos
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_Auditoria_Productos_Update')
    DROP TRIGGER trg_Auditoria_Productos_Update;
GO

CREATE TRIGGER trg_Auditoria_Productos_Update
ON Productos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Auditoria (
        tabla_afectada, operacion, id_registro, 
        datos_anteriores, datos_nuevos
    )
    SELECT 
        'Productos',
        'UPDATE',
        d.id_producto,
        CONCAT('SKU:', d.sku, ' Stock:', d.stock_actual, ' Precio:', d.precio_venta),
        CONCAT('SKU:', i.sku, ' Stock:', i.stock_actual, ' Precio:', i.precio_venta)
    FROM deleted d
    INNER JOIN inserted i ON d.id_producto = i.id_producto;
END
GO

PRINT 'Base de datos SGI-GuateMart creada exitosamente';
PRINT 'Usuario por defecto: admin / Password: admin123';
PRINT 'IMPORTANTE: Cambiar la contraseña del administrador en producción';
GO