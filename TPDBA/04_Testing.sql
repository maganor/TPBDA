USE Com5600G01
GO 

EXEC Procedimientos.CargarValorDolar
GO

DECLARE @PATH VARCHAR(255) = 'C:\Users\santi\ArchivosTPBDA'
DECLARE @FullPath VARCHAR(500) = @PATH + '\Informacion_complementaria.xlsx'

----Primero que todo, cargamos la tabla de Clasificacion de Productos con el SP:
--EXEC Procedimientos.CargarClasificacion @direccion = @FullPath
									
----Cargamos las Sucursales con el SP:
--EXEC Procedimientos.CargarSucursales	@direccion = @FullPath	

----Cargamos los Empleados con el SP:
--EXEC Procedimientos.CargarEmpleados		@direccion = @FullPath
																										
----Cargamos el Catalogo con el SP:
--SET @FullPath = @PATH + '\Productos\catalogo.csv'
--EXEC Procedimientos.CargarCatalogo		@direccion = @FullPath,
--										@terminator = ','

----Cargamos los Productos Importados con el SP:
--SET @FULLPATH = @PATH + '\Productos\Productos_importados.xlsx'
--EXEC Procedimientos.CargarImportados	@direccion = @FullPath

----Cargamoslos Accesorios Electronicos con el SP:
--SET @FULLPATH = @PATH + '\Productos\Electronic accessories.xlsx'
--EXEC Procedimientos.CargarElectronic	@direccion = @FullPath
																	
--Cargamos las Ventas Registradas con el SP:
SET @FULLPATH = @PATH + '\Ventas_registradas.csv'
EXEC Procedimientos.CargarHistorialTemp	@direccion = @FullPath, 
										@terminator = ';'
			   																		
GO

EXEC Procedimientos.CargarHistorial
GO

EXEC Procedimientos.CargarFacturasDesdeHistorial
GO

EXEC Productos.PesificarPrecios
GO

DECLARE @PATH VARCHAR(255) = 'C:\Users\santi\ArchivosTPBDA'
DECLARE @FULLPATH VARCHAR(500) = @PATH + '\Productos\catalogo.csv'
EXEC Procedimientos.CargarCatalogo 
    @direccion = @FULLPATH,
    @terminator = ','


--Para verificar la carga:
SELECT * FROM Complementario.ValorDolar
GO
SELECT * FROM Productos.Catalogo
GO
SELECT * FROM ##Historial		--Revisar
GO
DROP TABLE ##Historial
SELECT * FROM Complementario.CategoriaDeProds
GO
SELECT * FROM Complementario.Empleados
GO
SELECT * FROM Complementario.Sucursales
GO
SELECT * FROM Ventas.Facturas
GO
SELECT * FROM Ventas.Facturas
GO

DELETE FROM Productos.Catalogo 

--------PRUEBAS
 EXEC Procedimientos.AgregarFactura		@cantidad = 4,
										@tipoCliente = 'Member',
										@genero = 'Male',
										@empleado = '257020',
										@tipoFactura = 'A',
										@medioDePago = 'Ewallet',
										@producto = 'Cerveza Amstel',
										@ciudad = 'Yangon',
										@id = '898-04-2719'
GO

SELECT * FROM Ventas.Facturas as f
WHERE f.Id = '898-04-2719'

--DELETE FROM Ventas.Facturas 
--WHERE Id = '898-04-2719'

-------------
EXEC Procedimientos.AgregarEmpleado		@Nombre = 'Coscu',
										@Apellido = 'Army',
										@DNI = '44485891',
										@Direccion = 'CumbiaPeposa 1900',
										@EmailPersonal = 'holamundo@gmail.com',
										@EmailEmpresa = 'holaempresa@gmail.com',
										@CUIL = '11111111112',
										@Cargo = 'papu',
										@Sucursal = 'San Justo',
										@Turno = 'TM',
										@FraseClave = 'AvenidaSiempreViva742'
GO

EXEC Procedimientos.EliminarEmpleado @Legajo = '257035'


EXEC Procedimientos.ActualizarEmpleado	@Legajo = '257035',
										@Direccion = 'enrique segoviano 1944',
										@EmailPersonal = 'Bombaloca@gmail.com',
										@Cargo = 'Jefe',
										@Sucursal = 'Ramos Mejia',
										@Turno = 'Jornada completa',
										@FraseClave = 'AvenidaSiempreViva742'
GO		

SELECT * FROM Complementario.Empleados
-------------
EXEC Procedimientos.EliminarProductoCatalogo	@nombreProd = 'Aceite de aguacate Ethnos'	
GO

-------------
EXEC Procedimientos.AgregarMedioDePago @nombreING = 'Debit card',
                                       @nombreESP = 'Tarjeta de debito'
GO 

EXEC Procedimientos.EliminarMedioDePago @id = '4'
GO

SELECT * FROM Complementario.MediosDePago
GO
-------------
EXEC Procedimientos.AgregarCliente
    @Nombre = 'Juan Fer Perez',
    @TipoCliente = 'VIP',
    @Genero = 'M',
	@DNI = 43525943;
GO

EXEC Procedimientos.ModificarCliente
	@IdCliente = 3,										--revisar uso de id
    @TipoClienteNuevo = 'NORMAL';
GO

EXEC Procedimientos.ModificarCliente
    @IdCliente = 2,
    @TipoClienteNuevo = 'VIP';
GO

SELECT * FROM Complementario.Clientes
GO

EXEC Procedimientos.EliminarCliente
    @IdCliente = 3;
GO
-------------
EXEC Procedimientos.AgregarSucursal @Ciudad = 'Pekin',
                                    @ReemplazarPor = 'Moron',
                                    @Direccion = 'Aguero 1800',
                                    @Horario = 'Lunes a Viernes de 8 am - 9 pm y Sabados y Domingos de 8 am - 8 pm',
                                    @Telefono = '0912-1831'									
GO


EXEC Procedimientos.EliminarSucursal @id = '4'
GO

SELECT * FROM Complementario.Sucursales
GO
-------------
EXEC Procedimientos.GenerarNotaCredito @IdFactura = '898-04-2717'
GO

EXEC Procedimientos.EliminarNotaCredito @Id = '1'
GO

SELECT * FROM Ventas.NotasCredito
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
    
    EXEC @Error = CargarFacturas 
        @IdCliente = 123, 
        @IdSucursal = 1, 
        @Empleado = 101, 
        @TipoFactura = 'A', 
        @IdMedioPago = 5;

    IF @Error <> 0		-- Verificar si ocurrió un error en CargarFacturas
    BEGIN
        THROW;		-- Nos vamos
    END;

    EXEC AgregarProducto @IdProducto = 101;
    EXEC AgregarProducto @IdProducto = 102;

    DECLARE @IdFactura INT;
    SET @IdFactura = (SELECT TOP 1 IdFactura FROM Ventas.Facturas ORDER BY IdFactura DESC); 

    EXEC FinalizarCompra @IdFactura = @IdFactura;

    COMMIT TRANSACTION;
    PRINT 'Compra finalizada con éxito. Factura generada.';
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en el proceso de finalización de la compra. Transacción revertida.';
END CATCH;