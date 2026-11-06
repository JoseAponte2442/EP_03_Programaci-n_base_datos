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

---

## Actividad 2: Procedimientos Almacenados de Mantenimiento

**Contexto y Problema:** Operaciones de mantenimiento reutilizables sobre las tablas existentes (`Producto`), permitiendo altas y actualizaciones controladas desde el servidor.

### 1. Script T-SQL: Procedimientos Almacenados

```sql
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
```

### 2. Casos de Prueba y Evidencias de Ejecución


```sql
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
```


## Actividad 03: Diseño de una operación transaccional

Contexto:
Una operación organizacional requiere que varios cambios se consideren como una unidad lógica.

Problema:
Si una parte del proceso no corresponde al resultado esperado, los cambios no deben quedar aplicados de forma parcial.

Solución y script transaccional:
Para resolver esto, primero creamos una tabla complementaria HistorialMovimientos y luego implementamos un procedimiento almacenado con una transacción explícita.

```sql
use NovaMarket;
go

--Creación de la tabla HistorialMovimientos (para la transacción)
create table HistorialMovimientos (
    IdMovimiento int identity(1,1) primary key,
    IdProducto int,
    CantidadSalida int,
    FechaRegistro datetime default getdate(),
    Estado varchar(20)
);
go



--Procedimiento almacenado con transacción explícita
create OR alter procedure sp_RegistrarSalidaInventario
    @IdProducto int,
    @CantidadSalida int
as
begin
    set nocount on;

    begin transaction;

    begin try
        if @CantidadSalida <= 0
        begin
            raiserror('La cantidad de salida debe ser mayor a cero.', 16, 1);
        end

        declare @StockActual int;
        select @StockActual = Stock from Producto 
        where IdProducto = @IdProducto;

        if @StockActual is null
        begin
            raiserror('El producto no existe.', 16, 1);
        end

        if @StockActual < @CantidadSalida
        begin
            raiserror('Stock insuficiente para realizar la operación.', 16, 1);
        end



        --Operaciones agrupadas
        update Producto 
        set Stock = Stock - @CantidadSalida 
        where IdProducto = @IdProducto;
        
        insert into HistorialMovimientos (IdProducto, CantidadSalida, Estado)
        values (@IdProducto, @CantidadSalida, 'COMPLETADO');

        commit transaction;
        print 'Transacción confirmada (COMMIT): Salida registrada exitosamente.';
    end try
    begin catch

        if @@trancount > 0
        begin
            rollback transaction;
            print 'Transacción cancelada (ROLLBACK): No se aplicaron cambios parciales.';
        end

        print 'Detalle del error: ' + error_message();
    end catch
end;
go
```

**Criterios de Confirmación y Cancelación:**
- **Confirmación (commit):** Se ejecuta únicamente si las dos operaciones lógicas (el `update` del stock y el `insert` en el historial) se completan con éxito sin arrojar errores dentro del bloque `try`.
- **Cancelación (rollback):** Se ejecuta si se activa alguna regla de negocio (como intentar registrar una cantidad negativa o solicitar más stock del existente) o si ocurre un error del servidor. El bloque `catch` intercepta el fallo, deshace cualquier cambio y protege los datos.

**Diferencia entre comportamientos transaccionales:**
- **De autoconfirmación (Autocommit):** Cada instrucción individual (como un solo `update`) se confirma o se cancela automáticamente por sí sola tras ejecutarse. No permite agrupar operaciones.
- **Implícito:** SQL Server inicia una transacción autom[atica en segundo plano al detectar comandos de modificación de datos, pero la deja abierta; obliga a emitir un comando `commit` o `rollback` para finalizarla.
- **Explícito:** Es el modelo utilizado en nuestra solución y con él definimos de forma manual y exacta dónde inicia la unidad lógica de trabajo (mediante `begin transaction`) y controla cuándo confirmarla o deshacerla según la lógica del negocio.
