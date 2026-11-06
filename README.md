# EP_03_Programacion_base_datos

📋 Contenido de las Actividades

Actividad 1: Identificación del proceso a automatizar

Contexto y Problema: Migración de la lógica de negocio repetitiva desde las aplicaciones cliente hacia el servidor SQL Server para evitar sobrecarga de red y vulnerabilidades.

Entradas y Salidas:

Entradas: @IdEquipo (INT), @NuevoEstado (VARCHAR), @Observaciones (TEXT).

Salidas: @CodigoRetorno (INT), @Mensaje (VARCHAR).

Reglas de Negocio: Validación de existencia de equipos y restricción para no dar de baja equipos con mantenimientos pendientes.

Diagrama de Flujo (Pseudocódigo):

### Proceso de Actualización de Estado de Equipos

**Lógica del Pseudocódigo:**
```sql
INICIO
  Recibir parámetros (@IdEquipo, @NuevoEstado, @Observaciones)
  Validar existencia del equipo en la tabla Equipos
  SI el equipo no existe ENTONCES Retornar error (-1)
  Verificar restricciones de órdenes abiertas
  SI existen órdenes abiertas Y @NuevoEstado = 'Dado de Baja' ENTONCES Retornar error (-2)
  Ejecutar UPDATE y retornar éxito (0)
FIN
```

**Códigos de Retorno:**
* `0`: Éxito. El estado del equipo se actualizó correctamente.
* `-1`: Error. El equipo especificado en `@IdEquipo` no existe.
* `-2`: Error. No se puede dar de baja un equipo con órdenes de trabajo abiertas.



Actividad 2: Procedimientos almacenados de mantenimiento 

USE NovaMarket;
GO

CREATE OR ALTER PROCEDURE sp_InsertarProducto
    @Nombre NVARCHAR(100),
    @Precio DECIMAL(10,2),
    @Stock INT,
    @NuevoId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @Precio <= 0
    BEGIN
        RAISERROR('El precio del producto debe ser mayor a cero.', 16, 1);
        RETURN;
    END;

    IF @Stock < 0
    BEGIN
        RAISERROR('El stock inicial no puede ser negativo.', 16, 1);
        RETURN;
    END;

    INSERT INTO Producto (Nombre, Precio, Stock)
    VALUES (@Nombre, @Precio, @Stock);

    SET @NuevoId = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE sp_ActualizarStockProducto
    @IdProducto INT,
    @NuevoStock INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Producto WHERE IdProducto = @IdProducto)
    BEGIN
        RETURN -1;
    END;

    IF @NuevoStock < 0
    BEGIN
        RETURN -2;
    END;

    UPDATE Producto
    SET Stock = @NuevoStock
    WHERE IdProducto = @IdProducto;

    RETURN 0;
END;
GO

DECLARE @IdGenerado INT;

EXEC sp_InsertarProducto 
    @Nombre = 'Laptop Pro 15', 
    @Precio = 1250.00, 
    @Stock = 20, 
    @NuevoId = @IdGenerado OUTPUT;

SELECT @IdGenerado AS [ID_Producto_Creado];
GO

DECLARE @ResultadoActualizacion INT;

EXEC @ResultadoActualizacion = sp_ActualizarStockProducto 
    @IdProducto = 1, 
    @NuevoStock = 18;

SELECT @ResultadoActualizacion AS [Codigo_Resultado_Retorno];
GO
