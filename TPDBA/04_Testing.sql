
--Trabajo Practico Integrador - Bases de Datos Aplicada:
--Fecha de Entrega: 15/11/2024
--Comisión: 02-5600
--Grupo: 01
--Integrantes:
--Antola Ortiz, Mauricio Gabriel  -       44613237 
--Tempra, Francisco               -       44485891
--Villegas Brandolini, Lucas      -       44459666
--Zapata, Santiago                -       44525943

--Consignas que se cumplen:
--Siempre que se entreguen módulos de código fuente deben acompañarse de scripts de testing. Los juegos de prueba deben entregarse 
--en un archivo separado al script del fuente,aunque se incluya en el mismo proyecto. Todo módulo ejecutable (SP, función), debe ser
--utilizado en al menos una prueba. Deben utilizarse comentarios para indicar el resultado esperado de cada prueba. Por ejemplo,
--si un juego de prueba pretende demostrar que un dato se valida y por fallar la validación no se completa la transacción, 
--el comentario debe indicar la validación, por qué falla y qué evidencia se presenta (mensaje por consola, error, etc.).

---TESTING:

USE Com5600G01
GO 

EXEC Ajustes.CargarValorDolar
GO

DECLARE @PATH VARCHAR(255) = 'C:\Users\kerse\Desktop\TP_integrador_Archivos'
DECLARE @FullPath VARCHAR(500) = @PATH + '\Informacion_complementaria.xlsx'

--Primero que todo, cargamos la tabla de Clasificacion de Productos con el SP:
EXEC Carga.CargarClasificacion			@direccion = @FullPath
									
--Cargamos las Sucursales con el SP:
EXEC Carga.CargarSucursales				@direccion = @FullPath	

--Cargamos los Empleados con el SP:
EXEC Carga.CargarEmpleados				@direccion = @FullPath

EXEC Carga.CargarMediosDePago			@direccion = @FullPath
																										
--Cargamos el Catalogo con el SP:
SET @FullPath = @PATH + '\Productos\catalogo.csv'
EXEC Carga.CargarCatalogo				@direccion = @FullPath,
										@terminator = ','

SET @FULLPATH = @PATH + '\Productos\Productos_importados.xlsx'
EXEC Carga.CargarImportados				@direccion = @FullPath

--Cargamoslos Accesorios Electronicos con el SP:
SET @FULLPATH = @PATH + '\Productos\Electronic accessories.xlsx'
EXEC Carga.CargarElectronic				@direccion = @FullPath
																	
--Cargamos las Ventas Registradas con el SP:
SET @FULLPATH = @PATH + '\Ventas_registradas.csv'
EXEC Carga.CargarHistorialTemp			@direccion = @FullPath, 
										@terminator = ';'
			   																		
GO

--Se pasa el "historial viejo" a la nueva tabla:
EXEC Carga.CargarFacturasDesdeHistorial    
GO

--Se pasan a pesos los precios del catalogo:
EXEC Ajustes.PesificarPrecios
GO

--Para verificar la carga:
SELECT * FROM Complementario.ValorDolar
GO
SELECT * FROM Productos.Catalogo
GO
SELECT * FROM Complementario.MediosDePago
GO
SELECT * FROM Productos.CategoriaDeProds  
GO
SELECT * FROM Sucursal.Empleados
GO
SELECT * FROM Sucursal.Sucursales
GO
SELECT * FROM Ventas.Facturas
GO
SELECT * FROM Ventas.DetalleVentas
GO

		-----------------------------------------------
		--------------- ZONA DE TESTEOS ---------------
		-----------------------------------------------


--------Test Agregar Empleado--------
EXEC Sucursal.AgregarEmpleado			@Nombre = 'Howard',								--Existoso
										@Apellido = 'Wolowitz',
										@DNI = '44485891',
										@Direccion = 'CumbiaPeposa 1900',
										@EmailPersonal = 'holamundo@gmail.com',   
										@EmailEmpresa = 'holaempresa@gmail.com',
										@CUIL = '20-44485891-2',
										@Cargo = 'Cajero',
										@Sucursal = 'Ramos Mejia',
										@Turno = 'TM'
GO

EXEC Sucursal.AgregarEmpleado			@Nombre = 'Howard',								--Error por DNI duplicado
										@Apellido = 'Wolowitz',
										@DNI = '44485891',
										@Direccion = 'CumbiaPeposa 1900',
										@EmailPersonal = 'holamundo@gmail.com',   
										@EmailEmpresa = 'holaempresa@gmail.com',
										@CUIL = '20-44485891-2',
										@Cargo = 'Supervisor',
										@Sucursal = 'Ramos Mejia',
										@Turno = 'TM'
GO

--------Test Actualizar Empleado--------
EXEC Sucursal.ActualizarEmpleado		@Legajo = '257035',								--Exitoso
										@Direccion = 'enrique segoviano 1944',
										@EmailPersonal = 'Bombaloca@gmail.com',
										@Cargo = 'Gerente de sucursal',
										@Sucursal = 'San Justo',
										@Turno = 'Jornada completa'
GO

EXEC Sucursal.ActualizarEmpleado		@Legajo = '257100',								--Error por no encontrar el legajo
										@Direccion = 'Florencio Varela 1903',
										@EmailPersonal = 'estoesunemailfalso@gmail.com',
										@Cargo = 'Supervisor',
										@Sucursal = 'Lomas del Mirador',
										@Turno = 'Jornada completa'
GO

--------Test Eliminar Empleado--------
EXEC Sucursal.EliminarEmpleado @Legajo = '257035'										--Exitoso
GO

EXEC Sucursal.EliminarEmpleado @Legajo = '257200'										--Error por no encontrar el legajo
GO
--------Mostrar Empleados--------
SELECT * FROM Sucursal.Empleados
GO

--------Test Agregar Medio de Pago--------
EXEC MedioDePago.AgregarMedioDePago		@nombreING = 'Debit card',						--Exitoso
										@nombreESP = 'Tarjeta de debito'
GO 

EXEC MedioDePago.AgregarMedioDePago		@nombreING = 'Credit card',						--Error por Medio de pago duplicado
										@nombreESP = 'Tarjeta de credito'
GO

--------Test Eliminar Medio de Pago--------
EXEC MedioDePago.EliminarMedioDePago	@id = '4'										--Exitoso
GO

EXEC MedioDePago.EliminarMedioDePago	@id = '10'										--Error por no encontrar el ID del Medio de pago
GO

--------Mostrar Medios de Pago--------
SELECT * FROM Complementario.MediosDePago
GO

--------Test Agregar Cliente--------
EXEC Ventas.AgregarCliente				@Nombre = 'Juan Fernando Quintero',				--Exitoso
										@Genero = 'Hombre',
										@DNI = 43525943;
								
GO

EXEC Ventas.AgregarCliente				@Nombre = 'Celia Fernandez',					--Error	por DNI duplicado
										@Genero = 'Mujer',
										@DNI = 43525943;
								
GO

--------Tests Modificar Clientes--------
EXEC Ventas.ModificarCliente			@IdCliente = 5,									--Exitoso
										@TipoClienteNuevo = 'VIP';						--(Con idea de agregar mas tipos de cliente a futuro)										
GO

EXEC Ventas.ModificarCliente			@IdCliente = 11,								--Error por no encontrar el ID del cliente
										@TipoClienteNuevo = 'VIP';  										
GO

--------Test Eliminar Cliente--------
EXEC Ventas.EliminarCliente			@IdCliente = 5;										--Exitoso   
GO

EXEC Ventas.EliminarCliente			@IdCliente = 15;									--Error por no encontrar el ID del cliente 
GO

--------Mostrar Clientes--------
SELECT * FROM Ventas.Clientes
GO

--------Test Agregar Sucursal--------
EXEC Sucursal.AgregarSucursal			@Ciudad = 'Pekin',								--Exitoso
										@ReemplazarPor = 'Moron',
										@Direccion = 'Aguero 1800',
										@Horario = 'Lunes a Viernes de 8 am - 9 pm y Sabados y Domingos de 8 am - 8 pm',
										@Telefono = '0912-1831'									
GO

EXEC Sucursal.AgregarSucursal			@Ciudad = 'Yangon',								--Error por ya existir esa sucursal en ese lugar
										@ReemplazarPor = 'San Justo',
										@Direccion = 'Av. Brig. Gral. Juan Manuel de Rosas 3634, B1754 San Justo, Provincia de Buenos Aires',
										@Horario = 'L a V 8?a. m.–9?p. m. S y D 9 a. m.-8?p. m.',
										@Telefono = '5555-5551'									
GO

--------Test Eliminar Sucursal--------
EXEC Sucursal.EliminarSucursal			@id = '4'										--Exitoso
GO

EXEC Sucursal.EliminarSucursal			@id = '25'										--Error porque no existe dicha sucursal
GO

--------Mostrar Sucursales--------
SELECT * FROM Sucursal.Sucursales
GO

----------------Test Transaccion Compra----------------
BEGIN TRANSACTION;  

BEGIN TRY
    DECLARE @Error INT;
    
    EXEC @Error = Ventas.CargarFacturas
		@IdCliente = 0, 
        @IdSucursal = 1, 
        @Empleado = 257020, 
        @TipoFactura = 'A', 
        @IdMedioPago = 1;
    IF @Error <> 0		-- Verifica si ocurrió un error en CargarFacturas
	BEGIN
        THROW 50000, 'ERROR', 1	
	END
	
	--------Test Productos que SI Estan--------
    EXEC Ventas.AgregarProducto @IdProducto = 104;  
	EXEC Ventas.AgregarProducto @IdProducto = 105;
	EXEC Ventas.AgregarProducto @IdProducto = 10;
	EXEC Ventas.AgregarProducto @IdProducto = 18;
	EXEC Ventas.AgregarProducto @IdProducto = 18;
	EXEC Ventas.AgregarProducto @IdProducto = 18;
	EXEC Ventas.AgregarProducto @IdProducto = 18;

	--------Test Producto que NO Esta--------
	--EXEC Ventas.AgregarProducto @IdProducto = 7000;

	--------Test Cancelar Compra--------
	--EXEC Ventas.CancelarCompra; 

    DECLARE @IdFactura INT;
    SET @IdFactura = (SELECT TOP 1 IdFactura FROM Ventas.Facturas ORDER BY IdFactura DESC);

    EXEC Ventas.FinalizarCompra @IdFactura = @IdFactura;
    COMMIT TRANSACTION;
    PRINT 'Compra finalizada con éxito. Factura generada.';
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en el proceso de finalización de la compra. Transacción revertida.';
END CATCH;

--------Mostrar Facturas--------
SELECT * FROM Ventas.facturas

--------Mostrar Detalle Ventas--------
SELECT * FROM Ventas.DetalleVentas

--------Test nota de credito Exitosa--------
EXEC NotaCredito.GenerarNotaCredito
    @IdFactura = 1001,  
    @IdProducto = 104, 
    @Cantidad = 1; 

--------Test Nota de credito Fallida--------		No existe ese ID de Factura
EXEC NotaCredito.GenerarNotaCredito
    @IdFactura = 1020,  
    @IdProducto = 104, 
    @Cantidad = 1; 

--------Test Elimnar Nota de Credito--------
EXEC NotaCredito.EliminarNotaCredito @Id = 1;

--------Mostrar Notas de Credito--------
SELECT * FROM NotaCredito.NotasDeCredito

--------Test Mostrar Reporte--------
SELECT * FROM Ventas.MostrarReporte ORDER BY IdFactura ASC

--------Test Agregar/Actualizar Producto--------
EXEC Productos.AgregarOActualizarProductoCatalogo	@Nombre = 'Cosecha tardia blanco',	--Nuevo Producto
													@Precio = 5000,			
													@IdCategoria = 140

SELECT * FROM Productos.Catalogo WHERE nombre = 'Cosecha tardia blanco'
GO

EXEC Productos.AgregarOActualizarProductoCatalogo	@Nombre = 'Cosecha tardia blanco',
													@Precio = 4750,			--Actualiza Precio
													@IdCategoria = 140

SELECT * FROM Productos.Catalogo WHERE nombre = 'Cosecha tardia blanco'
GO

EXEC Productos.AgregarOActualizarProductoCatalogo	@Nombre = 'Cosecha tardia blanco',
													@Precio = 4750,			
													@IdCategoria = 300	--Error categoria inexistente

--------Test Eliminar Producto--------
EXEC Productos.EliminarProducto		@id = 6530 -- Exitoso
GO

SELECT * FROM Productos.Catalogo WHERE nombre = 'Cosecha tardia blanco'
GO

EXEC Productos.EliminarProducto		@id = 15403 -- Error no existe
GO

--------Test Agregar Categoria--------
EXEC Productos.AgregarCategoria		@NombreLinea = 'Almacen',						--Exitoso
									@NombreProd = 'galletitas_dulces'
GO

EXEC Productos.AgregarCategoria		@NombreLinea = 'Almacen',						--Error por ya existir
									@NombreProd = 'aceitunas_y_encurtidos'
GO

SELECT * FROM Productos.CategoriaDeProds
--------Test Eliminar Categoria--------
EXEC Productos.EliminarCategoria	@NombreLinea = 'Almacen',						--Exitoso
									@NombreProd = 'galletitas_dulces'

GO

EXEC Productos.EliminarCategoria	@NombreLinea = 'Almacen',						--Error	porque no existe
									@NombreProd = 'galletitas_de_agua'

GO

SELECT * FROM Productos.CategoriaDeProds

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
EXEC Reportes.MenosVendidosPorMes @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
GO

DECLARE @xml XML;
EXEC Reportes.TotalAcumuladoVentas @Fecha = '2024-11-15', @Sucursal = 'San Justo', @XMLResultado = @xml OUTPUT; --escribir fecha de hoy
GO
