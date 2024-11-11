USE Com5600G01
GO 

EXEC Procedimientos.CargarValorDolar
GO

DECLARE @PATH VARCHAR(255) = 'C:\Users\kerse\Desktop\TP_integrador_Archivos'
DECLARE @FullPath VARCHAR(500) = @PATH + '\Informacion_complementaria.xlsx'

--Primero que todo, cargamos la tabla de Clasificacion de Productos con el SP:
EXEC Carga.CargarClasificacion @direccion = @FullPath
									
--Cargamos las Sucursales con el SP:
EXEC Carga.CargarSucursales	@direccion = @FullPath	

--Cargamos los Empleados con el SP:
EXEC Carga.CargarEmpleados		@direccion = @FullPath
																										
--Cargamos el Catalogo con el SP:
SET @FullPath = @PATH + '\Productos\catalogo.csv'
EXEC Carga.CargarCatalogo		@direccion = @FullPath,
										@terminator = ','

--Cargamos los Productos Importados con el SP:
SET @FULLPATH = @PATH + '\Productos\Productos_importados.xlsx'
EXEC Carga.CargarImportados	@direccion = @FullPath

--Cargamoslos Accesorios Electronicos con el SP:
SET @FULLPATH = @PATH + '\Productos\Electronic accessories.xlsx'
EXEC Carga.CargarElectronic	@direccion = @FullPath
																	
--Cargamos las Ventas Registradas con el SP:
SET @FULLPATH = @PATH + '\Ventas_registradas.csv'
EXEC Carga.CargarHistorialTemp	@direccion = @FullPath, 
										@terminator = ';'
			   																		
GO

EXEC Carga.CargarHistorial
GO

--EXEC Carga.CargarFacturasDesdeHistorial     REVISAR
GO

EXEC Productos.PesificarPrecios
GO


--Para verificar la carga:
SELECT * FROM Complementario.ValorDolar
GO
SELECT * FROM Productos.Catalogo
GO
SELECT * FROM ##Historial		
GO
SELECT * FROM Complementario.CategoriaDeProds  --ojear x las ddas
GO
SELECT * FROM Complementario.Empleados
GO
SELECT * FROM Complementario.Sucursales
GO
SELECT * FROM Ventas.Facturas
GO


DELETE FROM Productos.Catalogo 

--------PRUEBAS

SELECT * FROM Ventas.Facturas as f
WHERE f.Id = '898-04-2719'

--DELETE FROM Ventas.Facturas 
--WHERE Id = '898-04-2719'

-------------
EXEC Empleado.AgregarEmpleado			@Nombre = 'Coscu',
										@Apellido = 'Army',
										@DNI = '44485891',
										@Direccion = 'CumbiaPeposa 1900',
										@EmailPersonal = 'holamundo@gmail.com',
										@EmailEmpresa = 'holaempresa@gmail.com',
										@CUIL = '11111111112',
										@Cargo = 'papu',
										@Sucursal = 'Yangon',
										@Turno = 'TM'
GO

EXEC Empleado.EliminarEmpleado @Legajo = '257035'


--EXEC Empleado.ActualizarEmpleado	@Legajo = '257035',
--										@Direccion = 'enrique segoviano 1944',
--										@EmailPersonal = 'Bombaloca@gmail.com',
--										@Cargo = 'Jefe',
--										@Sucursal = 'Ramos Mejia',
--										@Turno = 'Jornada completa'
--GO		

SELECT * FROM Complementario.Empleados
-------------
SELECT * from Productos.Catalogo WHERE nombre = 'Aceite de aguacate Ethnos'
EXEC Producto.EliminarProducto @id = 1	
SELECT * from Productos.Catalogo WHERE nombre = 'Aceite de aguacate Ethnos'

GO

-------------
EXEC MedioDePago.AgregarMedioDePago @nombreING = 'Debit card',
                                       @nombreESP = 'Tarjeta de debito'
GO 

EXEC MedioDePago.EliminarMedioDePago @id = '4'
GO

SELECT * FROM Complementario.MediosDePago
GO
-------------
EXEC Cliente.AgregarCliente
    @Nombre = 'Juan Fer Perez',
    @Genero = 'M',
	@DNI = 43525943;
GO


SELECT * from Complementario.Clientes
EXEC Cliente.ModificarCliente
	@IdCliente = 2,										--revisar uso de id
    @TipoClienteNuevo = 'NORMAL';
GO

EXEC Cliente.ModificarCliente
    @IdCliente = 2,
    @TipoClienteNuevo = 'VIP';
GO

SELECT * FROM Complementario.Clientes
GO

EXEC Cliente.EliminarCliente
    @IdCliente = 2;
GO
-------------
EXEC Sucursal.AgregarSucursal @Ciudad = 'Pekin',
                                    @ReemplazarPor = 'Moron',
                                    @Direccion = 'Aguero 1800',
                                    @Horario = 'Lunes a Viernes de 8 am - 9 pm y Sabados y Domingos de 8 am - 8 pm',
                                    @Telefono = '0912-1831'									
GO


EXEC Sucursal.EliminarSucursal @id = '4'
GO

SELECT * FROM Complementario.Sucursales
GO
-------------
EXEC NotaCredito.GenerarNotaCredito @IdFactura = 1, @IdProducto = 5, @Cantidad = 2
GO

EXEC NotaCredito.EliminarNotaCredito @Id = '1'
GO

SELECT * FROM Ventas.NotasDeCredito
GO

----------Ejecución de los Reportes XML
DECLARE @xml XML;
EXEC Reportes.GenerarReporteMensual @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;
GO

DECLARE @xml XML;
EXEC Reportes.GenerarReporteTrimestral @XMLResultado = @xml OUTPUT
GO

DECLARE @xml XML;
EXEC Reportes.GenerarReportePorRangoFechas @FechaInicio = '2019-01-01', @FechaFin = '2019-03-31', @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;
GO

DECLARE @xml XML;
EXEC Reportes.GenerarReportePorRangoFechasSucursal @FechaInicio = '2019-01-01', @FechaFin = '2019-03-31', @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;
GO

DECLARE @xml XML;
EXEC Reportes.Top5ProductosPorSemana @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;
GO

DECLARE @xml XML;
EXEC Reportes.Menor5ProductosPorMes @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;
GO

DECLARE @xml XML;
EXEC Reportes.TotalAcumuladoVentas @Fecha = '2019-03-15', @Sucursal = 'Ramos Mejia', @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;
GO
--

BEGIN TRANSACTION;  

BEGIN TRY
    DECLARE @Error INT;
    
    EXEC @Error = DetalleVenta.CargarFacturas
		@IdCliente = 0, 
        @IdSucursal = 1, 
        @Empleado = 257020, 
        @TipoFactura = 'A', 
        @IdMedioPago = 1;
    IF @Error <> 0		-- Verificar si ocurrió un error en CargarFacturas
    BEGIN
        THROW 50000, 'ERRRRROORRRR', 1		-- Nos vamos
    END;
    EXEC DetalleVenta.AgregarProducto @IdProducto = 104;  --modificar borrar tambla temp
    --EXEC DetalleVenta.AgregarProducto @IdProducto = 102;
	--EXEC DetalleVenta.CancelarCompra; 

    DECLARE @IdFactura INT;
    SET @IdFactura = (SELECT TOP 1 IdFactura FROM Ventas.Facturas ORDER BY IdFactura DESC); 

    EXEC DetalleVenta.FinalizarCompra @IdFactura = @IdFactura;
    COMMIT TRANSACTION;
    PRINT 'Compra finalizada con éxito. Factura generada.';
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en el proceso de finalización de la compra. Transacción revertida.';
END CATCH;

select * from ventas.facturas

select * from Ventas.DetalleVentas

EXEC NotaCredito.GenerarNotaCredito
    @IdFactura = 1008,  
    @IdProducto = 101, 
    @Cantidad = 1;     


select * from ventas.NotasDeCredito

exec NotaCredito.EliminarNotaCredito @Id = 1;

EXEC Procedimientos.MostrarReporte
