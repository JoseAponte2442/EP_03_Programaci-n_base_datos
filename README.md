# EP_03_Programacion_base_datos

📋 Contenido de las Actividades

# Actividad 1: Identificación del Proceso a Automatizar

## Caso de Estudio

La organización necesita administrar información relacionada con clientes, productos y operaciones mediante una base de datos en Microsoft SQL Server. Actualmente, los usuarios realizan tareas repetitivas de mantenimiento desde sus aplicaciones, por lo que se requiere trasladar parte de la lógica de negocio al servidor para mejorar la reutilización, el control y la consistencia de los datos.

---

# Proceso Seleccionado

## Mantenimiento de Productos

El proceso consiste en registrar nuevos productos y actualizar el stock de los productos existentes.

Estas operaciones son ejecutadas frecuentemente por los usuarios del sistema y requieren validaciones para garantizar la integridad de la información almacenada en la base de datos.

---

# Entradas y Salidas

## Proceso: Registrar Producto

### Entradas

- Nombre del producto
- Precio del producto
- Stock inicial

### Salidas

- Identificador (ID) generado automáticamente para el producto

### Reglas de Negocio

- El precio debe ser mayor que cero.
- El stock inicial no puede ser negativo.

---

## Proceso: Actualizar Stock

### Entradas

- ID del producto
- Nuevo stock

### Salidas

- Código de resultado de la operación

### Reglas de Negocio

- El producto debe existir.
- El nuevo stock no puede ser negativo.

### Códigos de Retorno

| Código | Descripción |
|----------|-------------|
| 0 | Actualización exitosa |
| -1 | El producto no existe |
| -2 | El stock es inválido |

---

# Pseudocódigo del Proceso

## Registro de Producto

```text
Inicio

Recibir Nombre
Recibir Precio
Recibir Stock

Si Precio <= 0
    Mostrar error
    Finalizar
Fin Si

Si Stock < 0
    Mostrar error
    Finalizar
Fin Si

Insertar producto en la base de datos

Obtener ID generado

Devolver ID

Fin
```

## Actualización de Stock

```text
Inicio

Recibir IdProducto
Recibir NuevoStock

Si el producto no existe
    Retornar -1
Fin Si

Si NuevoStock < 0
    Retornar -2
Fin Si

Actualizar Stock

Retornar 0

Fin
```

---

# Relación con la Arquitectura Cliente/Servidor

```text
+---------------------------+
|          CLIENTE          |
|  Aplicación del Usuario   |
+------------+--------------+
             |
             | Ejecuta
             | Procedimientos
             V
+---------------------------+
|         SERVIDOR          |
|        SQL SERVER         |
|                           |
| sp_InsertarProducto       |
| sp_ActualizarStockProducto|
+------------+--------------+
             |
             | Acceso
             V
+---------------------------+
|      BASE DE DATOS        |
|         Productos         |
+---------------------------+
```

---

# Justificación de la Automatización

La implementación de este proceso mediante procedimientos almacenados en SQL Server ofrece las siguientes ventajas:

- Centraliza las reglas de negocio en el servidor.
- Evita duplicar validaciones en múltiples aplicaciones cliente.
- Garantiza la integridad de los datos.
- Facilita el mantenimiento del sistema.
- Reduce errores producidos por entradas incorrectas.
- Permite reutilizar la misma lógica desde diferentes aplicaciones.
- Disminuye el tráfico entre cliente y servidor al ejecutar las validaciones directamente en la base de datos.

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
  ### Por Andrés Francisco Pimentel Saldaña

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

A continuación, adjuntaré una captura del SQL Server Management en la que se muestra que no se encontraron problemas en el código:
<img width="624" height="905" alt="{827E1CE4-1E21-403A-8D8E-F6D380B0E2DF}" src="https://github.com/user-attachments/assets/aab4ca81-2ed9-4b80-a339-18c87e92fed2" />

