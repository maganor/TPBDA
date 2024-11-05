USE Com5600G01
GO 

DECLARE @PATH VARCHAR(255) = 'E:\UNLAM\Carrera\Bases de Datos Aplicada\TP\TP_integrador_Archivos'
DECLARE @FullPath VARCHAR(500) = @PATH + '\Productos\catalogo.csv'

--Cargamos la tabla catalogo con el SP:
EXEC Procedimientos.CargarCSV		@direccion = @FullPath,
									@terminator = ',',
									@tabla = '##Catalogo'

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

EXEC Procedimientos.LlenarCatalogoFinal 
GO
EXEC Procedimientos.CargarVentasAReg
GO

--Para verificar la carga:
SELECT * FROM ##Catalogo
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
SELECT * FROM Productos.CatalogoFinal
GO
SELECT * FROM Ventas.VtasAReg
GO