USE Com5600G01
GO 

DECLARE @PATH VARCHAR(255) = 'C:\Users\kerse\Desktop\TP_integrador_Archivos'
DECLARE @FullPath VARCHAR(500) = @PATH + '\Productos\catalogo.csv'

--Cargamos la tabla catalogo con el SP:
EXEC Procedimientos.CargarCSV		@direccion = @FullPath,
									@terminator = ',',
									@tabla = '##CatalogoTemp'

SET @FULLPATH = @PATH + '\Ventas_registradas.csv'
--Cargamos la tabla historial con el SP:
EXEC Procedimientos.CargarCSV	@direccion = @FullPath, 
								@terminator = ';',
								@tabla = '##Historial'   
--Cargamos las hojas del archivo de Info Complementaria con el SP:
SET @FULLPATH = @PATH + '\Informacion_complementaria.xlsx'
--Hoja: Clasificacion de productos
EXEC Procedimientos.CargarClasificacion @direccion = @FullPath,
										@tabla = 'ClasificacionDeProductos',
										@pagina =  'Clasificacion productos',
										@esquema = 'Complementario'
--Hoja: Empleados
EXEC Procedimientos.CargarEmpleados		@direccion = @FullPath,
										@tabla = 'Empleados',
										@pagina =  'Empleados',
										@esquema = 'Complementario'
--Hoja: Sucursales
EXEC Procedimientos.CargarSucursales	@direccion = @FullPath,
										@tabla = 'Sucursales',
										@pagina =  'Sucursal',
										@esquema = 'Complementario'

SET @FULLPATH = @PATH + '\Productos\Electronic accessories.xlsx'
--Cargamos el archivo de Accesorios Electronicos con el SP:
EXEC Procedimientos.CargarElectronic	@direccion = @FullPath,
										@tabla = '##ElectronicAccessories',
										@pagina =  'Sheet1'
										

SET @FULLPATH = @PATH + '\Productos\Productos_importados.xlsx'
--Cargamos el archivo de Productos Importados con el SP:
EXEC Procedimientos.CargarImportados	@direccion = @FullPath,
										@tabla = '##ProductosImportados',
										@pagina = 'Listado de Productos'
										
GO

EXEC Procedimientos.LlenarCatalogo 
GO
EXEC Procedimientos.CargarVentas
GO
EXEC Procedimientos.MostrarFacturas
GO

--Para verificar la carga:
SELECT * FROM ##CatalogoTemp
GO
SELECT * FROM ##ProductosImportados
GO
SELECT * FROM ##ElectronicAccessories
GO
SELECT * FROM ##Historial
GO
SELECT * FROM Complementario.ClasificacionDeProductos
GO
SELECT * FROM Complementario.Empleados
GO
SELECT * FROM Complementario.Sucursales
GO
SELECT * FROM Productos.Catalogo
GO
SELECT * FROM Ventas.Facturas
GO

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

DELETE FROM Ventas.Facturas 
WHERE Id = '898-04-2719'

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
										@Turno = 'TM'
GO

EXEC Procedimientos.EliminarEmpleado @Legajo = '257035'


EXEC Procedimientos.ActualizarEmpleado	@Legajo = '257035',
										@Direccion = 'enrique segoviano 1944',
										@EmailPersonal = 'Bombaloca@gmail.com',
										@Cargo = 'Jefe',
										@Sucursal = 'Ramos Mejia',
										@Turno = 'Jornada completa'
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