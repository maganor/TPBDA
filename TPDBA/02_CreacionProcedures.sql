
---IMPORTACION DE ARCHIVOS .CSV Y .XLSX:

USE Com5600G01
GO

--Para el .xlsx:
--Para cargar los XLSX tuvimos que cambiar algo de los permisos de windows.
--Se busca services.msc, dentro de ese programa se busca SQL SERVER(SQLEXPRESS), 
--click derecho propiedades, pestania inicio sesion y seleccionar Cuenta del sistema local(o algo parecido)
--Antes, para que funcione este SP:
DROP SCHEMA IF EXISTS Carga
GO
CREATE SCHEMA Carga
GO

sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE;
GO

CREATE OR ALTER FUNCTION Procedimientos.ArreglarLetras(@str NVARCHAR(100)) RETURNS NVARCHAR(100)
BEGIN

    SET @str = REPLACE(@str, 'Ã', '')
    SET @str = REPLACE(@str, '¡', 'á')
    SET @str = REPLACE(@str, '©', 'é')
    SET @str = REPLACE(@str, NCHAR(0xAD), 'í')
    SET @str = REPLACE(@str, '³', 'ó') 
    SET @str = REPLACE(@str, 'º', 'ú')
    SET @str = REPLACE(@str, '±', 'ñ')

    return @str;
END;	
GO

--Para insertar los datos de los archivos
--Para el .csv:
--Archivo de Catalogo:

CREATE OR ALTER PROCEDURE Carga.CargarCatalogo
    @direccion VARCHAR(255),						-- Parámetro para la ruta del archivo
    @terminator CHAR(1)                             -- Delimitador de campo
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS ##CatalogoTemp
    CREATE TABLE ##CatalogoTemp(
        Id INT,
        Categoria VARCHAR(100),
        Nombre NVARCHAR(100),
        Precio DECIMAL(6,2),
        Precio_Ref DECIMAL(6,2),
        Unidad_Ref VARCHAR(10),
        Fecha DATETIME
    );

    DECLARE @sql NVARCHAR(MAX); 

    SET @sql = N'
    BULK INSERT ##CatalogoTemp
    FROM ''' + @direccion + '''
    WITH (
        FIELDTERMINATOR = ''' + @terminator + ''',
        ROWTERMINATOR = ''0x0A'',
        CODEPAGE = ''65001'',
        FIRSTROW = 2,
        FORMAT = ''CSV''
    );';

    EXEC sp_executesql @sql;

    ALTER TABLE ##CatalogoTemp ADD IdCategoria INT;					--Añade IdCategoria para usarlo luego en la comparación

	UPDATE ##CatalogoTemp
	SET Nombre = REPLACE(Nombre, NCHAR(0x5358), 'ñ')				--Corrige errores por la Ñ

    UPDATE ct SET ct.IdCategoria = cp.Id							--Añade el valor de IdCategoria al Producto
    FROM ##CatalogoTemp ct
        JOIN Complementario.CategoriaDeProds cp ON cp.Producto = ct.Categoria

    INSERT INTO Productos.Catalogo(Nombre,Precio,Proveedor,IdCategoria)	 --Inserta al catalogo si está el mismo nombre ni la categoria
    SELECT ct.Nombre,ct.Precio,'-' AS Proveedor,ct.IdCategoria            
    FROM ##CatalogoTemp ct
    WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo c 
                      WHERE c.Nombre = ct.Nombre AND c.IdCategoria = ct.IdCategoria)

    DROP TABLE ##CatalogoTemp

END;
GO

--Archivo de Ventas_registradas:									
CREATE OR ALTER PROCEDURE Carga.CargarHistorialTemp
    @direccion VARCHAR(255),
    @terminator CHAR(1)
AS
BEGIN
    DROP TABLE IF EXISTS ##HistorialTemp
    CREATE TABLE ##HistorialTemp (
        IdFactura CHAR(11),
        TipoFactura VARCHAR(1),
        Ciudad VARCHAR(100),
        TipoCliente VARCHAR(10),
        Genero VARCHAR(6),
        Producto VARCHAR(100),
        PrecioUni VARCHAR(10),
        Cantidad VARCHAR(10),
        Fecha VARCHAR(15),
        Hora VARCHAR(10),
        MedioPago VARCHAR(30),
        Empleado VARCHAR(10),
        IdPago VARCHAR(30)
    );

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    BULK INSERT ##HistorialTemp
    FROM ''' + @direccion + '''
    WITH (
        FIELDTERMINATOR = ''' + @terminator + ''',
        ROWTERMINATOR = ''0x0A'',
        CODEPAGE = ''65001'',
        FIRSTROW = 2,
        FORMAT = ''CSV''
    );';

    EXEC sp_executesql @sql;
END;
GO

CREATE OR ALTER PROCEDURE Carga.CargarHistorial
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS ##Historial
    CREATE TABLE ##Historial (
        IdFactura CHAR(11),
        TipoFactura CHAR(1),
        Ciudad VARCHAR(100),
        TipoCliente VARCHAR(10),
        Genero VARCHAR(6),
        Producto VARCHAR(100),
        PrecioUni DECIMAL(10,2),
        Cantidad INT,
        Fecha DATE,
        Hora TIME(0),
        MedioPago VARCHAR(30),
        Empleado INT,
        IdPago VARCHAR(30)
    );

    INSERT INTO ##Historial(IdFactura,TipoFactura,Ciudad,TipoCliente,Genero,Producto,PrecioUni,Cantidad,Fecha,Hora,MedioPago,Empleado,IdPago)
    SELECT
		IdFactura,
		TipoFactura,
		Ciudad,
		TipoCliente,
		Genero,
		Producto,
		CAST(PrecioUni AS DECIMAL(10, 2)),
		CAST(Cantidad AS INT),
		TRY_CONVERT(DATE, Fecha, 101),
		CAST(Hora AS TIME(0)),
		MedioPago,
		CAST(Empleado AS INT) AS Empleado,
		IdPago
	FROM ##HistorialTemp;

    DROP TABLE ##HistorialTemp;

	UPDATE ##Historial
	SET Producto = Procedimientos.ArreglarLetras(Producto)

END;
GO

--Para los .xlsx:
--Archivo de Productos_importados:
CREATE OR ALTER PROCEDURE Carga.CargarImportados
    @direccion VARCHAR(100)  
AS
BEGIN
    SET NOCOUNT ON;

	DROP TABLE IF EXISTS #ProductosImportados

    CREATE TABLE #ProductosImportados(
        IdProducto INT,
        Nombre VARCHAR(100),
        Proveedor VARCHAR(100),
        Categoria VARCHAR(50),
        CantidadPorUnidad VARCHAR(50),
        PrecioUnidad DECIMAL(6,2)
    );

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    INSERT INTO #ProductosImportados
    SELECT 
        TRY_CAST(IdProducto AS INT),
        CAST(NombreProducto AS VARCHAR(100)),
        CAST(Proveedor AS VARCHAR(100)),
        CAST([Categoría] AS VARCHAR(50)),
        CAST(CantidadPorUnidad AS VARCHAR(50)),
        TRY_CAST(REPLACE(REPLACE(PrecioUnidad, ''$'', ''''), '' '', '''') AS DECIMAL(6,2))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.16.0'',
        ''Excel 12.0 Xml; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [Listado de Productos$]''
    ) AS a;';

    EXEC sp_executesql @sql;

    INSERT INTO Complementario.CategoriaDeProds(LineaDeProducto, Producto)	--Inserta la Categoria del archivo en el tabla de Categorias
    SELECT DISTINCT i.Categoria, i.Nombre
    FROM #ProductosImportados i
    WHERE NOT EXISTS (SELECT 1 FROM Complementario.CategoriaDeProds c 
					  WHERE c.LineaDeProducto = i.Categoria AND c.Producto = i.Nombre);

    INSERT INTO Productos.Catalogo(Nombre, Precio, Proveedor, IdCategoria)	--Inserta en el Catalogo si no tiene el mismo nombre ni IdCategoria
    SELECT i.Nombre,i.PrecioUnidad,i.Proveedor,cp.Id
    FROM #ProductosImportados i 
		JOIN Complementario.CategoriaDeProds cp ON cp.LineaDeProducto = i.Categoria AND cp.Producto = i.Nombre
    WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo c
					  WHERE c.Nombre = i.Nombre AND c.IdCategoria = cp.Id);

    DROP TABLE #ProductosImportados;

END;
GO

--Archivo de Electronic Accessories:
CREATE OR ALTER PROCEDURE Carga.CargarElectronic
    @direccion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

	DROP TABLE IF EXISTS #ElectronicAccessories

    CREATE TABLE #ElectronicAccessories(
        Nombre NVARCHAR(100),
        PrecioUSD DECIMAL(6,2) 
    );

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    INSERT INTO #ElectronicAccessories (Nombre, PrecioUSD)
    SELECT 
        CAST(Product AS NVARCHAR(100)),
        TRY_CAST(REPLACE(REPLACE([Precio Unitario en dolares], ''$'', ''''), '' '', '''') AS DECIMAL(6,2))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.16.0'',
        ''Excel 12.0 Xml; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [Sheet1$]''
    ) AS a;';

    EXEC sp_executesql @sql;

    IF NOT EXISTS (SELECT 1 FROM Complementario.CategoriaDeProds WHERE LineaDeProducto = 'Accesorios Electronicos')
    BEGIN
        INSERT INTO Complementario.CategoriaDeProds (LineaDeProducto, Producto)		--Agrega la Categoria a la tabla de Categorias
        VALUES ('Accesorios Electronicos', 'Accesorios Electronicos');
    END;

    DECLARE @IdCategoria INT;														--Obtiene el Id de la categoria
    SELECT @IdCategoria = c.Id 
		FROM Complementario.CategoriaDeProds c
		WHERE c.LineaDeProducto = 'Accesorios Electronicos';

    INSERT INTO Productos.Catalogo(Nombre, Precio, Proveedor, IdCategoria)			--Inserta en el catalogo si no está
    SELECT ea.Nombre,ea.PrecioUSD,'-' AS Proveedor,@IdCategoria
    FROM #ElectronicAccessories ea
	WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo C 
					  WHERE C.Nombre = ea.Nombre);
    
	DROP TABLE #ElectronicAccessories;

END;
GO

--Archivo Informacion_Complementaria / Clasificacion Productos:
CREATE OR ALTER PROCEDURE Carga.CargarClasificacion
    @direccion VARCHAR(100)       
AS
BEGIN
    SET NOCOUNT ON;
   
	DROP TABLE IF EXISTS #ClasificacionTemp
	CREATE TABLE #ClasificacionTemp (
    LineaDeProducto VARCHAR(100),
    Producto VARCHAR(100)
	);

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO #ClasificacionTemp (LineaDeProducto, Producto)
    SELECT 
        CAST([Línea de producto] AS VARCHAR(100)),
        CAST(Producto AS VARCHAR(100))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [Clasificacion productos$]''
    );';

    EXEC sp_executesql @sql;

    INSERT INTO Complementario.CategoriaDeProds (LineaDeProducto, Producto)		--Inserta la categoria a la tabla final si no está
    SELECT ct.LineaDeProducto,ct.Producto
    FROM #ClasificacionTemp ct
    WHERE NOT EXISTS (SELECT 1 FROM Complementario.CategoriaDeProds c
                      WHERE c.LineaDeProducto = ct.LineaDeProducto AND c.Producto = ct.Producto);

    DROP TABLE #ClasificacionTemp;

END;
GO

--Archivo Informacion_Complementaria / Empleados:
CREATE OR ALTER PROCEDURE Carga.CargarEmpleados
    @direccion VARCHAR(100)       
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #EmpleadosTemp
    CREATE TABLE #EmpleadosTemp (
        Legajo INT,
        Nombre VARCHAR(50),
        Apellido VARCHAR(50),
        DNI INT,
        Direccion VARCHAR(200),
        EmailPersonal VARCHAR(100),
        EmailEmpresa VARCHAR(100),
        CUIL VARCHAR(11),
        Cargo VARCHAR(50),
        Sucursal VARCHAR(100),
        Turno VARCHAR(25),
        EstaActivo BIT DEFAULT 1
    );

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO #EmpleadosTemp (Legajo, Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo, Sucursal, Turno, EstaActivo)
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
        CAST(Turno AS VARCHAR(25)),
        1  -- Valor predeterminado para EstaActivo
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [Empleados$] WHERE [Legajo/ID] IS NOT NULL''
    );';

    EXEC sp_executesql @sql;
	
	--Inserta el Empleado en la tabla final si no está
    INSERT INTO Complementario.Empleados (Legajo, Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo,IdSucursal, Turno, EstaActivo)
    SELECT e.Legajo,e.Nombre,e.Apellido,e.DNI,e.Direccion,e.EmailPersonal,e.EmailEmpresa,e.CUIL,e.Cargo,s.IdSucursal,e.Turno,e.EstaActivo
    FROM #EmpleadosTemp e
		JOIN Complementario.Sucursales s on s.ReemplazarPor = e.Sucursal
    WHERE NOT EXISTS (SELECT 1 FROM Complementario.Empleados c WHERE c.Legajo = e.Legajo);

    DROP TABLE #EmpleadosTemp;

END;
GO

CREATE OR ALTER PROCEDURE Carga.CargarSucursales
    @direccion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #SucursalesTemp
    CREATE TABLE #SucursalesTemp (
        Ciudad VARCHAR(100),
        ReemplazarPor VARCHAR(100),
        Direccion VARCHAR(200),
        Horario VARCHAR(100),
        Telefono VARCHAR(20)
    );

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO #SucursalesTemp (Ciudad, ReemplazarPor, Direccion, Horario, Telefono)
    SELECT 
        CAST(Ciudad AS VARCHAR(100)),  
        CAST([Reemplazar por] AS VARCHAR(100)) AS ReemplazarPor,  
        CAST(direccion AS VARCHAR(200)) AS Direccion,  
        CAST(Horario AS VARCHAR(100)) AS Horario,  
        CAST(Telefono AS VARCHAR(20)) AS Telefono  
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [sucursal$]''  
    );';

    EXEC sp_executesql @sql;

    INSERT INTO Complementario.Sucursales (Ciudad, ReemplazarPor, Direccion, Horario, Telefono)
    SELECT st.Ciudad, st.ReemplazarPor, st.Direccion, st.Horario, st.Telefono
    FROM #SucursalesTemp st																	--Inserta la sucursal si no está
    WHERE NOT EXISTS (SELECT 1 FROM Complementario.Sucursales s
					  WHERE s.Ciudad = st.Ciudad AND s.ReemplazarPor = st.ReemplazarPor
					  AND s.Direccion = st.Direccion);

    DROP TABLE #SucursalesTemp;
END;
GO

CREATE OR ALTER PROCEDURE Carga.CargarFacturasDesdeHistorial
AS
BEGIN
    INSERT INTO Ventas.Facturas (IdViejo,TipoFactura,Fecha,Hora,IdMedioPago,Empleado,IdSucursal,IdCliente)
    SELECT 
        H.IdFactura AS IdViejo,
        H.TipoFactura,
        CAST(H.Fecha AS DATE) AS Fecha, 
        CAST(H.Hora AS TIME(0)) AS Hora, 
        M.IdMDP AS IdMedioPago, 
        CAST(H.Empleado AS INT) AS Empleado,
        '-' AS IdSucursal, 
        '-' AS IdCliente 
    FROM ##Historial H
		JOIN Complementario.MediosDePago M ON H.MedioPago = M.NombreING; 
END;
GO

CREATE OR ALTER PROCEDURE Productos.PesificarPrecios
AS
BEGIN
    DECLARE @PrecioDolar DECIMAL(6,2);

    SELECT @PrecioDolar = PrecioAR
    FROM Complementario.ValorDolar

    UPDATE Productos.Catalogo
    SET Precio = Precio * @PrecioDolar;
END;
GO

--Ver procedimientos en esquema 'Procedimientos'
SELECT SCHEMA_NAME(schema_id) AS Esquema, name AS Procedimiento
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'Procedimientos';
GO