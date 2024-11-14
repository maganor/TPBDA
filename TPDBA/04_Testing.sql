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

EXEC Carga.CargarMediosDePago @direccion = @FullPath
																										
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

EXEC Carga.CargarFacturasDesdeHistorial    
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
SELECT * FROM Complementario.MediosDePago
GO
SELECT * FROM Complementario.CategoriaDeProds  --ojear x las ddas
GO
SELECT * FROM Complementario.Empleados
GO
SELECT * FROM Complementario.Sucursales
GO
SELECT * FROM Ventas.Facturas
GO
SELECT * FROM Ventas.DetalleVentas
GO

		-----------------------------------------------
		--------------- ZONA DE TESTEOS ---------------
		-----------------------------------------------


--------Test Agregar Empleado--------
EXEC Empleado.AgregarEmpleado			@Nombre = 'Howard',
										@Apellido = 'Wolowitz',
										@DNI = '44485891',
										@Direccion = 'CumbiaPeposa 1900',
										@EmailPersonal = 'holamundo@gmail.com',
										@EmailEmpresa = 'holaempresa@gmail.com',
										@CUIL = '11111111112',
										@Cargo = 'papu',
										@Sucursal = 'Yangon',
										@Turno = 'TM'
GO

--------Test Eliminar Empleado--------
EXEC Empleado.EliminarEmpleado @Legajo = '257035'

--------Test Actualizar Empleado--------
EXEC Empleado.ActualizarEmpleado		@Legajo = '257035',
										@Direccion = 'enrique segoviano 1944',
										@EmailPersonal = 'Bombaloca@gmail.com',
										@Cargo = 'Jefe',
										@Sucursal = 'Ramos Mejia',
										@Turno = 'Jornada completa'
GO		

--------Mostrar Empleados--------
SELECT * FROM Complementario.Empleados
GO

--------Test Eliminar Producto--------
SELECT * from Productos.Catalogo WHERE nombre = 'Aceite de aguacate Ethnos'
GO
EXEC Producto.EliminarProducto @id = 847
GO
SELECT * from Productos.Catalogo WHERE nombre = 'Aceite de aguacate Ethnos'
GO

--------Test Agregar Medio de Pago--------
EXEC MedioDePago.AgregarMedioDePago		@nombreING = 'Debit card',
										@nombreESP = 'Tarjeta de debito'
GO 

--------Test Eliminar Medio de Pago--------
EXEC MedioDePago.EliminarMedioDePago @id = '4'
GO

--------Mostrar Medios de Pago--------
SELECT * FROM Complementario.MediosDePago
GO

--------Test Agregar Cliente--------
EXEC Cliente.AgregarCliente
								@Nombre = 'Juan Fer Perez',
								@Genero = 'M',
								@DNI = 43525943;
GO

--------Tests Modificar Clientes--------
EXEC Cliente.ModificarCliente
								@IdCliente = 5,
								@TipoClienteNuevo = 'VIP';  --Con idea de agregar mas tipos de cliente a futuro
GO

--------Test Eliminar Cliente--------
EXEC Cliente.EliminarCliente
								@IdCliente = 5;
GO

--------Mostrar Clientes--------
SELECT * FROM Complementario.Clientes
GO

--------Test Agregar Sucursal--------
EXEC Sucursal.AgregarSucursal @Ciudad = 'Pekin',
                                    @ReemplazarPor = 'Moron',
                                    @Direccion = 'Aguero 1800',
                                    @Horario = 'Lunes a Viernes de 8 am - 9 pm y Sabados y Domingos de 8 am - 8 pm',
                                    @Telefono = '0912-1831'									
GO

--------Test Eliminar Sucursal--------
EXEC Sucursal.EliminarSucursal @id = '4'
GO

SELECT * FROM Complementario.Sucursales
GO

----------Ejecución de los Reportes XML---------------
DECLARE @xml XML;
EXEC Reportes.GenerarReporteMensual @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
GO

DECLARE @xml XML;
EXEC Reportes.GenerarReporteTrimestral @XMLResultado = @xml OUTPUT
GO

DECLARE @xml XML;
EXEC Reportes.GenerarReportePorRangoFechas @FechaInicio = '2019-01-01', @FechaFin = '2019-03-31', @XMLResultado = @xml OUTPUT;
GO

DECLARE @xml XML;
EXEC Reportes.GenerarReportePorRangoFechasSucursal @FechaInicio = '2019-01-01', @FechaFin = '2019-03-31', @XMLResultado = @xml OUTPUT;
GO

DECLARE @xml XML;
EXEC Reportes.Top5ProductosPorSemana @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
GO

DECLARE @xml XML;
EXEC Reportes.Menor5ProductosPorMes @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
GO

DECLARE @xml XML;
EXEC Reportes.TotalAcumuladoVentas @Fecha = '2019-03-14', @Sucursal = 'Ramos Mejia', @XMLResultado = @xml OUTPUT;
GO

----------------Test Transaccion Compra----------------
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
	
	--------Test Productos que SI Estan--------
    EXEC DetalleVenta.AgregarProducto @IdProducto = 104;  --modificar borrar tambla temp
	EXEC DetalleVenta.AgregarProducto @IdProducto = 105;
	EXEC DetalleVenta.AgregarProducto @IdProducto = 10;
	EXEC DetalleVenta.AgregarProducto @IdProducto = 18;
	EXEC DetalleVenta.AgregarProducto @IdProducto = 18;
	EXEC DetalleVenta.AgregarProducto @IdProducto = 18;
	EXEC DetalleVenta.AgregarProducto @IdProducto = 18;

	--------Test Producto que NO Esta--------
	--EXEC DetalleVenta.AgregarProducto @IdProducto = 7000;

	--------Test Cancelar Compra--------
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

--------Mostrar Facturas--------
select * from ventas.facturas

--------Mostrar Detalle Ventas--------
select * from Ventas.DetalleVentas

--------Test nota de credito Exitosa--------
EXEC NotaCredito.GenerarNotaCredito
    @IdFactura = 1001,  
    @IdProducto = 104, 
    @Cantidad = 1; 

--------Test Nota de credito Fallida--------
EXEC NotaCredito.GenerarNotaCredito
    @IdFactura = 1020,  
    @IdProducto = 104, 
    @Cantidad = 1; 

--------Test Elimnar Nota de Credito--------
EXEC NotaCredito.EliminarNotaCredito @Id = 1;

--------Mostrar Notas de Credito--------
select * from ventas.NotasDeCredito

--------Test Mostrar Reporte--------
EXEC Procedimientos.MostrarReporte




-----------------------------------------------------------------
------------para debatir con el grupo----------------------------nuevo generar nota de credito

EXEC NotaCredito.GenerarNotaCredito
    @IdFactura = 1011,  
    @IdProducto = 18, 
    @Cantidad = 1; 

--------Mostrar Facturas--------
select * from ventas.facturas

--------Mostrar Detalle Ventas--------
select * from Ventas.DetalleVentas