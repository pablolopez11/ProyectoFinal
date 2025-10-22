-- Insertar proveedores de ejemplo
INSERT INTO Proveedores (nit, nombre_proveedor, nombre_contacto, telefono, email, direccion, activo)
VALUES 
('12345678-9', 'Distribuidora Central S.A.', 'Juan P�rez', '2345-6789', 'ventas@distcentral.com', 'Zona 10, Guatemala', 1),
('98765432-1', 'Importadora del Norte', 'Mar�a L�pez', '2234-5678', 'contacto@impnorte.com', 'Zona 1, Guatemala', 1),
('55555555-5', 'Comercial El Progreso', 'Carlos Mart�nez', '2456-7890', 'info@elprogreso.com', 'Zona 4, Guatemala', 1),
('11111111-1', 'Mayorista La Econom�a', 'Ana Garc�a', '2567-8901', 'ventas@laeconomia.com', 'Zona 12, Guatemala', 1),
('22222222-2', 'Distribuciones R�pidas', 'Luis Rodr�guez', '2678-9012', 'contacto@distrapidas.com', 'Zona 7, Guatemala', 1);

-- Verificar que se insertaron
SELECT * FROM Proveedores;
GO