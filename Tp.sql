
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
GO

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

    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N' (
        Producto VARCHAR(100),
        [Precio Unitario en dolares] DECIMAL(6,2)
    );';

    EXEC sp_executesql @sql;

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


CREATE OR ALTER PROCEDURE Procedimientos.CargarClasificacion
    @direccion VARCHAR(100),
    @tabla VARCHAR(100),
    @pagina VARCHAR(100),
    @esquema VARCHAR(20)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N' (
        [Línea de producto] VARCHAR(100),
        Producto VARCHAR(100)
    );';

    EXEC sp_executesql @sql;

    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N'
    SELECT 
        CAST([Línea de producto] AS VARCHAR(100)),
        CAST(Producto AS VARCHAR(100))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [' + @pagina + N'$]''
    );';

    EXEC sp_executesql @sql;
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.CargarEmpleados
    @direccion VARCHAR(100),
    @tabla VARCHAR(100),
    @pagina VARCHAR(100),
    @esquema VARCHAR(20)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N' (
        Legajo INT NOT NULL,
        Nombre VARCHAR(50),
        Apellido VARCHAR(50),
        DNI INT,
        Direccion VARCHAR(200),
        [email personal] VARCHAR(100),
        [email empresa] VARCHAR(100),
        CUIL VARCHAR(11),
        Cargo VARCHAR(50),
        Sucursal VARCHAR(100),
        Turno VARCHAR(25)
    );';

    EXEC sp_executesql @sql;

    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N'
    SELECT 
        CAST([Legajo/ID] AS INT),
        CAST(Nombre AS VARCHAR(50)),
        CAST(Apellido AS VARCHAR(50)),
        CAST(DNI AS INT),
        CAST(Direccion AS VARCHAR(200)),
        CAST([email personal] AS VARCHAR(100)),
        CAST([email empresa] AS VARCHAR(100)),
        CAST(CUIL AS VARCHAR(11)),
        CAST(Cargo AS VARCHAR(50)),
        CAST(Sucursal AS VARCHAR(100)),
        CAST(Turno AS VARCHAR(25))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [' + @pagina + N'$] WHERE [Legajo/ID] IS NOT NULL''
    );';

    EXEC sp_executesql @sql;
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.CargarSucursales
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
        Ciudad VARCHAR(100),
        [Reemplazar por] VARCHAR(100),
        direccion VARCHAR(200),
        Horario VARCHAR(100),
        Telefono VARCHAR(20)
    );';

    EXEC sp_executesql @sql;

    -- Then, insert the data from Excel
    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N'
    SELECT 
        CAST(Ciudad AS VARCHAR(100)),
        CAST([Reemplazar por] AS VARCHAR(100)),
        CAST(direccion AS VARCHAR(200)),
        CAST(Horario AS VARCHAR(100)),
        CAST(Telefono AS VARCHAR(20))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [' + @pagina + N'$]''
    );';

    EXEC sp_executesql @sql;
END;
GO


--Ver procedimientos en esquema 'Procedimientos'
SELECT SCHEMA_NAME(schema_id) AS Esquema, name AS Procedimiento
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'Procedimientos';
GO

---------------------------------
--Dsp borrar
TRUNCATE TABLE Productos.Catalogo
GO
TRUNCATE TABLE Ventas.Historial
GO
DROP TABLE IF EXISTS Complementario.ClasificacionDeProductos
GO
DROP TABLE IF EXISTS Complementario.Empleados
GO
DROP TABLE IF EXISTS Complementario.Sucursales
GO
DROP TABLE IF EXISTS Productos.ElectronicAccessories
GO
DROP TABLE IF EXISTS Productos.ProductosImportados
GO
-----------------------------------


DECLARE @PATH VARCHAR(255) = 'C:\Users\kerse\Desktop\TP_integrador_Archivos'
DECLARE @FullPath VARCHAR(500) = @PATH + '\Productos\catalogo.csv'

--Cargamos la tabla catalogo con el SP:
EXEC Procedimientos.CargarCSV		@direccion = @FullPath,
									@terminator = ',',
									@tabla = 'Productos.Catalogo'

SET @FULLPATH = @PATH + '\Ventas_registradas.csv'
--Cargamos la tabla historial con el SP:
EXEC Procedimientos.CargarCSV	@direccion = @FullPath, 
								@terminator = ';',
								@tabla = 'Ventas.Historial'   
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
										@tabla = 'ElectronicAccessories',
										@pagina =  'Sheet1',
										@esquema = 'Productos'

SET @FULLPATH = @PATH + '\Productos\Productos_importados.xlsx'
--Cargamos el archivo de Productos Importados con el SP:
EXEC Procedimientos.CargarImportados	@direccion = @FullPath,
										@tabla = 'ProductosImportados',
										@pagina = 'Listado de Productos',
										@esquema = 'Productos'
GO


--Para verificar la carga:
SELECT * FROM Productos.Catalogo
GO
SELECT * FROM Ventas.Historial
GO
SELECT * FROM Complementario.ClasificacionDeProductos
GO
SELECT * FROM Complementario.Empleados
GO
SELECT * FROM Complementario.Sucursales
GO





---------------------------------------------------
--Dsp Borrar:											  				   


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

