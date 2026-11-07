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