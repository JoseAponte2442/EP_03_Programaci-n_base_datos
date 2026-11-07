
-- CASOS DE PRUEBA Y EVIDENCIAS (ACTIVIDAD 4)


USE NovaMarket;
GO

-- 1. Insertar el producto obligatorio para las pruebas
INSERT INTO Producto (Nombre, Precio, Stock) VALUES ('Laptop Pro 15', 1250.00, 20);
GO

-- 2. Ver estado inicial del producto
SELECT * FROM Producto;
GO

-- 3. PRUEBA 1: Caso Favorable (COMMIT - Salida exitosa de 5 unidades)
EXEC sp_RegistrarSalidaInventario @IdProducto = 1, @CantidadSalida = 5;
GO

-- Ver cómo bajó el stock a 15 y el registro en el historial
SELECT * FROM Producto;
SELECT * FROM HistorialMovimientos;
GO

-- 4. PRUEBA 2: Caso No Favorable (ROLLBACK - Intento fallido de retirar 500 unidades)
EXEC sp_RegistrarSalidaInventario @IdProducto = 1, @CantidadSalida = 500;
GO

-- Ver que el stock se mantiene intacto gracias al rollback
SELECT * FROM Producto;
GO