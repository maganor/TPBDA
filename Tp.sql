
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

DROP TABLE IF EXISTS ##Catalogo
GO
CREATE TABLE ##Catalogo(
	Id int primary key,
	Categoria varchar(100),
	Nombre varchar(100),
	Precio decimal(6,2),
	Precio_Ref decimal(6,2),
	Unidad_Ref varchar(10),
	Fecha datetime
)

DROP TABLE IF EXISTS Productos.CatalogoFinal
GO
CREATE TABLE Productos.CatalogoFinal(
	Id int IDENTITY (1,1) primary key,
	[Linea de Producto] varchar(100),
	Nombre varchar(100),
	Precio decimal(6,2),
	Proveedor varchar(100)
)

--Para ver que las tablas pertenezcan al esquema 'Productos'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Productos'
GO

CREATE SCHEMA Ventas
GO

DROP TABLE IF EXISTS ##Historial
GO
CREATE TABLE ##Historial(
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
	Linea_Prod varchar(100),
	Producto varchar(100),
	PrecioUni decimal(6,2),
	Cantidad int,
	Fecha date,
	Hora time(0),
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
    @pagina VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    -- Crear la tabla temporal global
    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@tabla) + N' (
        IdProducto INT NOT NULL,
        NombreProducto VARCHAR(100),
        Proveedor VARCHAR(100),
        Categoria VARCHAR(50),
        CantidadPorUnidad VARCHAR(50),
        PrecioUnidad DECIMAL(6,2),
        CONSTRAINT PK_' + @tabla + N' PRIMARY KEY (IdProducto)
    );';

    EXEC sp_executesql @sql;

    -- Insertar datos en la tabla temporal global
    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@tabla) + N'
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
    @pagina VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

	--Crea la tabla
    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@tabla) + N' (
        Producto VARCHAR(100),
        PrecioUSD DECIMAL(6,2)
    );';

    EXEC sp_executesql @sql;

	--Inserta los datos
    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@tabla) + N'
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

	--Crea la tabla
    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N' (
        [Línea de producto] VARCHAR(100),
        Producto VARCHAR(100)
    );';

    EXEC sp_executesql @sql;

	--Inserta los datos
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

	--Crea la tabla
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

	--Inserta los datos
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

    --Crea la tabla
    SET @sql = N'
    CREATE TABLE ' + QUOTENAME(@esquema) + N'.' + QUOTENAME(@tabla) + N' (
        Ciudad VARCHAR(100),
        [Reemplazar por] VARCHAR(100),
        direccion VARCHAR(200),
        Horario VARCHAR(100),
        Telefono VARCHAR(20)
    );';

    EXEC sp_executesql @sql;

    --Inserta los datos
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

CREATE OR ALTER PROCEDURE Procedimientos.LlenarCatalogoFinal 
AS
BEGIN 
    INSERT INTO Productos.CatalogoFinal ([Linea de Producto], Nombre, Precio, Proveedor)
    SELECT 
        cdp.[Línea de Producto], 
        c.Nombre, 
        c.Precio, 
        '-' AS Proveedor          
    FROM 
        ##Catalogo AS c
    JOIN 
        Complementario.ClasificacionDeProductos AS cdp ON c.Categoria = cdp.Producto;

    INSERT INTO Productos.CatalogoFinal([Linea de Producto], Nombre, Precio, Proveedor)
    SELECT
        'Accesorios Electronicos' AS Categoria,
        e.Producto,
        e.PrecioUSD,
        '-' AS Proveedor
    FROM
        ##ElectronicAccessories AS e
    INSERT INTO Productos.CatalogoFinal([Linea de Producto], Nombre, Precio, Proveedor)
    SELECT
        p.Categoria,
        p.NombreProducto,
        p.PrecioUnidad,
        p.Proveedor
    FROM
        ##ProductosImportados AS p

END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.CargarVentasAReg
AS
BEGIN 
    INSERT INTO Ventas.VtasAReg (
        Id, Tipo_Factura, Ciudad, Tipo_Cliente, Genero, Linea_Prod, Producto, PrecioUni, Cantidad, Fecha, Hora, MedioPago, Empleado, Sucursal
    )
    SELECT 
        h.Id,
        h.Tipo_Factura,
        h.Ciudad,
        h.Tipo_Cliente,
        h.Genero,
        h.Producto,         
        '-' AS Producto,              
        h.PrecioUni,
        h.Cantidad,
        h.Fecha,
        h.Hora,
        h.MedioPago,
        h.Empleado,             
        s.[Reemplazar por] 
    FROM 
        ##Historial AS h
    JOIN 
        Complementario.Sucursales AS s  
    ON 
        h.Ciudad = s.Ciudad;              
END;
GO

--Ver procedimientos en esquema 'Procedimientos'
SELECT SCHEMA_NAME(schema_id) AS Esquema, name AS Procedimiento
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'Procedimientos';
GO

---------------------------------
--Dsp borrar
--TRUNCATE TABLE Productos.CatalogoFinal
--GO
--TRUNCATE TABLE Ventas.Historial
--GO
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
---------------------------------------------------
--Dsp Borrar:											  				   

USE master
GO
DROP DATABASE Com5600G01
GO

SELECT * FROM ##ProductosImportados
GO

SELECT * FROM ##ElectronicAccessories
GO

SELECT * FROM Complementario.ClasificacionDeProductos
GO

SELECT * FROM Complementario.Empleados
GO

SELECT * FROM Complementario.MediosDePago
GO

SELECT * FROM Complementario.Sucursales
GO
---------------------------------------------------------------AAAAAAAAAAAAAAA
DROP TABLE IF EXISTS ##Catalogo
GO

DROP TABLE IF EXISTS ##Historial
GO
DROP TABLE IF EXISTS ##ElectronicAccessories
GO
DROP TABLE IF EXISTS ##ProductosImportados
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