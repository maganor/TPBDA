USE Com5600G01
GO

--Para el .xlsx:
--Para cargar los XLSX tuvimos que cambiar algo de los permisos de windows.
--Se busca services.msc, dentro de ese programa se busca SQL SERVER(SQLEXPRESS), 
--click derecho propiedades, pestania inicio sesion y seleccionar Cuenta del sistema local(o algo parecido)
--Antes, para que funcione este SP:
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

    SET @str = REPLACE(@str, '�', '')
    SET @str = REPLACE(@str, '�', '�')
    SET @str = REPLACE(@str, '�', '�') 
    SET @str = REPLACE(@str, '�', '�')
    SET @str = REPLACE(@str, '�', '�')
    SET @str = REPLACE(@str, '�', '�')
    SET @str = REPLACE(@str, NCHAR(0xAD), '�')

    return @str;
END;
GO

--Para insertar los datos de los archivos
--Para el .csv:
--Archivo de Catalogo:
CREATE OR ALTER PROCEDURE Procedimientos.CargarCatalogo
    @direccion VARCHAR(255),					-- Par�metro para la ruta del archivo
    @terminator CHAR(1)							-- Delimitador de campo
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM tempdb.sys.objects WHERE name = '##CatalogoTemp' AND type = 'U')
	BEGIN
		CREATE TABLE ##CatalogoTemp(
			Id INT,
			Categoria VARCHAR(100),
			Nombre NVARCHAR(100),
			Precio DECIMAL(6,2),
			Precio_Ref DECIMAL(6,2),
			Unidad_Ref VARCHAR(10),
			Fecha DATETIME        
		);
	END;

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

	--UPDATE ##CatalogoTemp SET Nombre = Procedimientos.ArreglarLetras(Nombre)

	ALTER TABLE ##CatalogoTemp ADD IdCategoria INT;

	UPDATE ct SET ct.IdCategoria = cp.Id
	FROM ##CatalogoTemp ct
		JOIN Complementario.CategoriaDeProds cp ON cp.Producto = ct.Categoria

	INSERT INTO Productos.Catalogo(Nombre,Precio,Proveedor,IdCategoria)
	SELECT ct.Nombre,ct.Precio,'-' AS Proveedor,ct.IdCategoria			--Pesificar precio
	FROM ##CatalogoTemp ct
	WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo c 
					  WHERE c.Nombre = ct.Nombre AND c.IdCategoria = ct.IdCategoria)

	DROP TABLE ##CatalogoTemp

END;
GO

--Archivo de Ventas_registradas:									REVISAR LA IMPORTACION A FACTURAS
USE Com5600G01
GO
CREATE OR ALTER PROCEDURE Procedimientos.CargarHistorialTemp
    @direccion VARCHAR(255),    
    @terminator CHAR(1)        
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM tempdb.sys.objects WHERE name = '##HistorialTemp' AND type = 'U')
    BEGIN
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
    END;

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

CREATE OR ALTER PROCEDURE Procedimientos.CargarHistorial
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM tempdb.sys.objects WHERE name = '##Historial' AND type = 'U')
    BEGIN
        CREATE TABLE ##Historial (
            IdFactura CHAR(11),
            TipoFactura CHAR(1),
            Ciudad VARCHAR(100),
            TipoCliente VARCHAR(10),
            Genero VARCHAR(6),
            Producto VARCHAR(100),
            PrecioUni DECIMAL(10,2),
            Cantidad INT,
            Fecha DATETIME,
            Hora TIME,
            MedioPago VARCHAR(30),
            Empleado INT,
            IdPago VARCHAR(30)
        );
    END;
    INSERT INTO ##Historial(
        IdFactura,
        TipoFactura,
        Ciudad,
        TipoCliente,
        Genero,
        Producto,
        PrecioUni,
        Cantidad,
        Fecha,
        Hora,
        MedioPago,
        Empleado,
        IdPago
    )
    SELECT
    IdFactura,
    TipoFactura,
    Ciudad,
    TipoCliente,
    Genero,
    Producto,
    CAST(PrecioUni AS DECIMAL(10, 2)),
    CAST(Cantidad AS INT),
    TRY_CONVERT(DATE, Fecha, 103),  
    TRY_CONVERT(TIME, Hora, 108),
    MedioPago,
    CAST(Empleado AS INT) AS Empleado,
    IdPago
    FROM ##HistorialTemp;

    DROP TABLE ##HistorialTemp;


END;
GO


--Para los .xlsx:
--Archivo de Productos_importados:
CREATE OR ALTER PROCEDURE Procedimientos.CargarImportados
    @direccion VARCHAR(100),                
    @pagina VARCHAR(100)                    
AS
BEGIN
    SET NOCOUNT ON;

	IF NOT EXISTS (SELECT * FROM tempdb.sys.objects WHERE name = '#ProductosImportados' AND type = 'U')
	BEGIN
		CREATE TABLE #ProductosImportados(
			IdProducto INT,
			Nombre NVARCHAR(100),
			Proveedor VARCHAR(100),
			Categoria VARCHAR(50),
			CantidadPorUnidad VARCHAR(50),
			PrecioUnidad DECIMAL(6,2),             
		);
	END;

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    INSERT INTO #ProductosImportados
    SELECT 
        CAST(IdProducto AS INT),
        CAST(NombreProducto AS NVARCHAR(100)),
        CAST(Proveedor AS VARCHAR(100)),
        CAST([Categor�a] AS VARCHAR(50)),
        CAST(CantidadPorUnidad AS VARCHAR(50)),
        CAST(REPLACE(REPLACE(PrecioUnidad, ''$'', ''''), '' '', '''') AS DECIMAL(6,2))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + QUOTENAME(@direccion, '''') + '; HDR=YES;'', 
        ''SELECT * FROM [' + QUOTENAME(@pagina, '''') + '$]''
    );';

    EXEC sp_executesql @sql;

	--Verificar esto si agregar el nombre o no
	INSERT INTO Complementario.CategoriaDeProds(LineaDeProducto,Producto)
	SELECT i.Categoria,i.Nombre
	FROM #ProductosImportados i
	WHERE NOT EXISTS (SELECT 1 FROM Complementario.CategoriaDeProds c 
					  WHERE c.LineaDeProducto = i.Categoria AND c.Producto = i.Nombre)
    
	INSERT INTO Productos.Catalogo(Nombre,Precio,Proveedor,IdCategoria)
	SELECT i.Nombre,i.PrecioUnidad,i.Proveedor,cp.Id			--Pesificar el precio
	FROM #ProductosImportados i 
		JOIN Complementario.CategoriaDeProds cp ON cp.LineaDeProducto = i.Categoria AND cp.Producto = i.Nombre
	WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo c
					  WHERE c.Nombre = i.Nombre AND c.IdCategoria = cp.Id)

	DROP TABLE #ProductosImportados
		
END;
GO

--Archivo de Electronic Accessories:
CREATE OR ALTER PROCEDURE Procedimientos.CargarElectronic
    @direccion VARCHAR(100),
    @pagina VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM tempdb.sys.objects WHERE name = '#ElectronicAccessories' AND type = 'U')
    BEGIN
        CREATE TABLE #ElectronicAccessories(
            Nombre NVARCHAR(100),
			PrecioUSD DECIMAL(6,2) 
        );
    END;

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO #ElectronicAccessories (Nombre, PrecioUSD)
    SELECT 
        CAST(Product AS NVARCHAR(100)),
        CAST(REPLACE([Precio Unitario en dolares], ''$'', '''') AS DECIMAL(6,2))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [' + @pagina + N'$]''
    );';

    EXEC sp_executesql @sql;

	IF NOT EXISTS (SELECT 1 FROM Complementario.CategoriaDeProds WHERE LineaDeProducto = 'Accesorios Electronicos')
    BEGIN
        INSERT INTO Complementario.CategoriaDeProds (LineaDeProducto, Producto)
        VALUES ('Accesorios Electronicos', 'Accesorios Electronicos');
    END

	DECLARE @IdCategoria INT
	SELECT @IdCategoria = c.Id 
	FROM Complementario.CategoriaDeProds c
	WHERE c.LineaDeProducto = 'Accesorios Electronicos'

	INSERT INTO Productos.Catalogo(Nombre,Precio,Proveedor,IdCategoria)
	SELECT ea.Nombre,ea.PrecioUSD,'-' AS Proveedor,@IdCategoria			--Pesificar Precio
	FROM #ElectronicAccessories ea
	WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo C
					  WHERE C.Nombre = ea.Nombre)

	DROP TABLE #ElectronicAccessories

END;
GO

--Archivo Informacion_Complementaria / Clasificacion Productos:
CREATE OR ALTER PROCEDURE Procedimientos.CargarClasificacion
    @direccion VARCHAR(100),       
    @pagina VARCHAR(100)           
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO Complementario.CategoriaDeProds (LineaDeProducto, Producto)
    SELECT 
        CAST([L�nea de producto] AS VARCHAR(100)),
        CAST(Producto AS VARCHAR(100))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [' + @pagina + N'$]''
    );';

    EXEC sp_executesql @sql;

END;
GO

--Archivo Informacion_Complementaria / Empleados:
CREATE OR ALTER PROCEDURE Procedimientos.CargarEmpleados
    @direccion VARCHAR(100),
    @pagina VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO Complementario.Empleados (Legajo,Nombre,Apellido,DNI,Direccion,EmailPersonal,EmailEmpresa,CUIL,Cargo,Sucursal,Turno,EstaActivo)
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
        1  
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [' + @pagina + N'$] WHERE [Legajo/ID] IS NOT NULL''
    );
    ';

    EXEC sp_executesql @sql;
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.CargarSucursales
    @direccion VARCHAR(100)  -- Solo se mantiene la direcci�n del archivo Excel
AS
BEGIN --test
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT * FROM tempdb.sys.objects WHERE name = '#SucursalesTemp')
    BEGIN
        CREATE TABLE #SucursalesTemp (
            Ciudad VARCHAR(100),
            ReemplazarPor VARCHAR(100),
            Direccion VARCHAR(200),
            Horario VARCHAR(100),
            Telefono VARCHAR(20)
        );
    END;

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO Complementario.Sucursales (Ciudad, ReemplazarPor, Direccion, Horario, Telefono)
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
END;
GO

--Ver procedimientos en esquema 'Procedimientos'
SELECT SCHEMA_NAME(schema_id) AS Esquema, name AS Procedimiento
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'Procedimientos';
GO