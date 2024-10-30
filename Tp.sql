
--Trabajo Practico Integrador - Bases de Datos Aplicada:
--Integrantes:
--Antola Ortiz, Mauricio Gabriel  -       44613237 
--Tempra, Francisco               -       44485891
--Villegas Brandolini, Lucas      -       44459666
--Zapata, Santiago                -       44525943


--Creacion:

CREATE DATABASE Com5600G01
GO

USE Com5600G01
GO

CREATE SCHEMA Productos
GO

DROP TABLE IF EXISTS Productos.Catalogo
GO
CREATE TABLE Productos.Catalogo(
	Id int primary key,
	Categoria varchar(100),
	Nombre varchar(100),
	Precio decimal(6,2),
	Precio_Ref decimal(6,2),
	Unidad_Ref varchar(10),
	Fecha datetime
)



--Para ver que las tablas pertenezcan al esquema 'Productos'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Productos'
GO

CREATE SCHEMA Ventas
GO

DROP TABLE IF EXISTS Ventas.Historial
GO
CREATE TABLE Ventas.Historial(
	Id char(11) primary key,
	Tipo_Factura char(1),
	Ciudad varchar(15),
	Tipo_Cliente char(6),
	Genero varchar(6),
	Producto varchar(100),
	PrecioUni decimal(6,2),
	Cantidad int,
	Fecha date,
	Hora time,
	MedioPago varchar(11),
	Empleado int,
	IdMedPago varchar(30)
)

DROP TABLE IF EXISTS Ventas.VtasAReg
GO
CREATE TABLE Ventas.VtasAReg(
	Id char(11) primary key,
	Tipo_Factura char(1),
	Ciudad varchar(15),
	Tipo_Cliente char(6),
	Genero varchar(6),
	Linea_Prod varchar(10),
	Producto varchar(100),
	PrecioUni decimal(6,2),
	Cantidad int,
	Fecha date,
	Hora time,
	MedioPago varchar(11),
	Empleado int,
	Sucursal varchar(17)
)

--Para ver que las tablas pertenezcan al esquema 'Ventas'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Ventas'
GO

--Se crea este esquema para la info complementaria.
CREATE SCHEMA Complementario
GO


DROP TABLE IF EXISTS Complementario.MonedaExtranjera
CREATE TABLE Complementario.MonedaExtranjera(
	Id int identity(1,1) primary key,
	Nombre char(3),
	PrecioAR decimal(6,2)
)
GO

--Para ver que las tablas pertenezcan al esquema 'Compementario'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Complementario'

INSERT INTO Complementario.MonedaExtranjera(Nombre,PrecioAR)
VALUES ('USD',1225)
GO


CREATE SCHEMA Procedimientos 
GO


--Para insertar los datos de los archivos
--Para el .csv:
CREATE OR ALTER PROCEDURE Procedimientos.CargarCSV
    @direccion VARCHAR(255),					-- Parámetro para la ruta del archivo
    @terminator CHAR(1),						-- Delimitador de campo
    @tabla VARCHAR(50)							-- Nombre de la tabla con esquema
AS
BEGIN
    DECLARE @sql NVARCHAR(500); 

    SET @sql = N'
    BULK INSERT ' + @tabla + '
    FROM ''' + @direccion + '''
    WITH (
        FIELDTERMINATOR = ''' + @terminator + ''',
        ROWTERMINATOR= ''0x0A'',
        CODEPAGE = ''65001'',
        FIRSTROW = 2,
        FORMAT = ''CSV''
    );';

    EXEC sp_executesql @sql;
END;
GO



--Para el .xlsx:

--Antes, para que funcione este SP:
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE;
GO



CREATE OR ALTER PROCEDURE Procedimientos.CargarImportados
    @direccion VARCHAR(100),
    @tabla VARCHAR(100),
    @pagina VARCHAR(100),
    @esquema VARCHAR(20)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    -- First, create the table with explicit column definitions
    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N' (
        IdProducto INT NOT NULL,
        NombreProducto VARCHAR(100),
        Proveedor VARCHAR(100),
        [Categoría] VARCHAR(50),
        CantidadPorUnidad VARCHAR(50),
        PrecioUnidad DECIMAL(6,2),
        CONSTRAINT PK_' + @tabla + N' PRIMARY KEY (IdProducto)
    );';

    EXEC sp_executesql @sql;

    -- Then, insert the data from Excel
    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N'
    SELECT 
        CAST(IdProducto AS INT),
        CAST(NombreProducto AS VARCHAR(100)),
        CAST(Proveedor AS VARCHAR(100)),
        CAST([Categoría] AS VARCHAR(50)),
        CAST(CantidadPorUnidad AS VARCHAR(50)),
        CAST(REPLACE(REPLACE(PrecioUnidad, ''$'', ''''), '' '', '''') AS DECIMAL(6,2))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [' + @pagina + N'$]''
    );';

    EXEC sp_executesql @sql;
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.CargarElectronic
    @direccion VARCHAR(100),
    @tabla VARCHAR(100),
    @pagina VARCHAR(100),
    @esquema VARCHAR(20)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    -- First, create the table with explicit column definitions
    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N' (
        Producto VARCHAR(100),
        [Precio Unitario en dolares] DECIMAL(6,2)
    );';

    EXEC sp_executesql @sql;

    -- Then, insert the data from Excel
    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N'
    SELECT 
        CAST(Product AS VARCHAR(100)),
        CAST([Precio Unitario en dolares] AS DECIMAL(6,2))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [' + @pagina + N'$]''
    );';

    EXEC sp_executesql @sql;
END;
GO

-------


--Ver procedimientos en esquema 'Procedimientos'
SELECT 
    SCHEMA_NAME(schema_id) AS Esquema,
    name AS Procedimiento
FROM 
    sys.procedures
WHERE 
    SCHEMA_NAME(schema_id) = 'Procedimientos';
GO

DECLARE @PATH VARCHAR(255) = 'C:\Users\kerse\Desktop\TP_integrador_Archivos'
DECLARE @FullPath VARCHAR(500) = @PATH + '\Productos\catalogo.csv'

--Cargamos la tabla catalogo con el sp
EXEC Procedimientos.CargarCSV		@direccion = @FullPath,
									@terminator = ',',
									@tabla = 'Productos.Catalogo'

SET @FULLPATH = @PATH + '\Ventas_registradas.csv'
--Cargamos la tabla historial con el sp
EXEC Procedimientos.CargarCSV	@direccion = @FullPath, 
								@terminator = ';',
								@tabla = 'Ventas.Historial'   
GO


SELECT * FROM Ventas.Historial
GO

SELECT * FROM Productos.Catalogo
GO





--cargamos la tabla ProductosImportados con el sp
EXEC Procedimientos.CargarXLSX	@direccion = N'C:\Users\kerse\Desktop\TP_integrador_Archivos\Productos\Productos_importados.xlsx',
								@tabla = 'ProductosImportados',
								@pagina = 'Listado de Productos',
								@esquema = 'Productos'
GO

											  
--cargamos la tabla ElectroinicAccessories						   
EXEC Procedimientos.CargarElectronic	@direccion = 'C:\Users\kerse\Desktop\TP_integrador_Archivos\Productos\Electronic accessories.xlsx',
										@tabla = 'ElectronicAccessories',
										@pagina =  'Sheet1',
										@esquema = 'Productos'
GO


--cargamos la tabla
EXEC Procedimientos.CargarXLSX	@direccion = 'C:\Users\kerse\Desktop\TP_integrador_Archivos\Informacion_complementaria.xlsx',
								@tabla = 'Sucursales',
								@pagina =  'sucursal',
								@esquema = 'Complementario'
GO


EXEC Procedimientos.CargarXLSX	@direccion = 'C:\Users\kerse\Desktop\TP_integrador_Archivos\Informacion_complementaria.xlsx',
								@tabla = 'Empleados',
								@pagina =  'Empleados',
								@esquema = 'Complementario'
GO


EXEC Procedimientos.CargarXLSX	@direccion = 'C:\Users\kerse\Desktop\TP_integrador_Archivos\Informacion_complementaria.xlsx',
								@tabla = 'MediosDePago',
								@pagina =  'medios de pago',
								@esquema = 'Complementario'
GO


EXEC Procedimientos.CargarXLSX	@direccion = 'C:\Users\kerse\Desktop\TP_integrador_Archivos\Informacion_complementaria.xlsx',
								@tabla = 'ClasificacionDeProductos',
								@pagina =  'Clasificacion productos',
								@esquema = 'Complementario'
GO

USE master
GO
DROP DATABASE Com5600G01
GO

SELECT * FROM Productos.ProductosImportados
GO

SELECT * FROM Productos.ElectronicAccessories
GO

SELECT * FROM Complementario.ClasificacionDeProductos
GO

SELECT * FROM Complementario.Empleados
GO

SELECT * FROM Complementario.MediosDePago
GO

SELECT * FROM Complementario.Sucursales
GO







TRUNCATE TABLE Productos.Catalogo
GO
TRUNCATE TABLE Ventas.Historial
GO



DROP TABLE IF EXISTS Productos.ProductosImportados
GO

DROP TABLE IF EXISTS Productos.Catalogo
GO

DROP TABLE IF EXISTS Ventas.Historial
GO

DROP TABLE IF EXISTS Ventas.VtasAReg
GO

DROP TABLE IF EXISTS Productos.ElectronicAccessories
GO

DROP TABLE IF EXISTS Complementario.ClasificacionDeProductos
GO

DROP TABLE IF EXISTS Complementario.ClasificacionDeProductos
GO

DROP TABLE IF EXISTS Complementario.MediosDePago
GO

DROP TABLE IF EXISTS Complementario.Sucursales
GO

DROP TABLE IF EXISTS Complementario.Empleados
GO



DROP PROCEDURE IF EXISTS Procedimientos.CargarCSV
GO

DROP PROCEDURE IF EXISTS Procedimientos.CargarXLSX
GO

DROP PROCEDURE IF EXISTS Procedimientos.CargarCSVConTemp
GO

DROP PROCEDURE IF EXISTS Procedimientos.CargarXLSXConAlter
GO

DROP PROCEDURE IF EXISTS Procedimientos.ModificarColumnas
GO

DROP PROCEDURE IF EXISTS Procedimientos.ModificarProductosImportados
GO


DROP SCHEMA IF EXISTS Productos
GO

DROP SCHEMA IF EXISTS Ventas
GO

DROP SCHEMA IF EXISTS Procedimientos
GO

DROP SCHEMA IF EXISTS Complementario
GO

