
--Trabajo Practico Integrador - Bases de Datos Aplicada:
--Fecha de Entrega: 15/11/2024
--ComisiÛn: 02-5600
--Grupo: 01
--Integrantes:
--Antola Ortiz, Mauricio Gabriel  -       44613237 
--Tempra, Francisco               -       44485891
--Villegas Brandolini, Lucas      -       44459666
--Zapata, Santiago                -       44525943

--Consignas que se cumplen:

--Entrega 4:
--Se requiere que importe toda la informaciÛn antes mencionada a la base de datos:
--ï Genere los objetos necesarios (store procedures, funciones, etc.) para importar los archivos antes mencionados. Tenga en cuenta 
--que cada mes se recibir·n archivos de novedades con la misma estructura, pero datos nuevos para agregar a cada maestro.
--ï Considere este comportamiento al generar el cÛdigo. Debe admitir la importaciÛn de novedades periÛdicamente.
--ï Cada maestro debe importarse con un SP distinto. No se aceptar·n scripts que realicen tareas por fuera de un SP.
--ï La estructura/esquema de las tablas a generar ser· decisiÛn suya. Puede que deba realizar procesos de transformaciÛn sobre los 
--maestros recibidos para adaptarlos a la estructura requerida.
--Los archivos CSV/JSON no deben modificarse. En caso de que haya datos mal cargados, incompletos, errÛneos, etc., deber· contemplarlo
--y realizar las correcciones en el fuente SQL. (SerÌa una excepciÛn si el archivo est· malformado y no es posible interpretarlo como 
--JSON o CSV). 

---IMPORTACION DE ARCHIVOS .CSV Y .XLSX:

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
EXEC sp_configure 'Ole Automation Procedures', 1; 
RECONFIGURE;
GO

DROP SCHEMA IF EXISTS Carga
GO
CREATE SCHEMA Carga
GO

CREATE OR ALTER FUNCTION Ajustes.ArreglarLetras(@str NVARCHAR(100)) RETURNS NVARCHAR(100)
BEGIN

    SET @str = REPLACE(@str, '√°', '·')
    SET @str = REPLACE(@str, '√©', 'È')
    SET @str = REPLACE(@str, '√' + NCHAR(0xAD), 'Ì')
    SET @str = REPLACE(@str, '√≥', 'Û') 
    SET @str = REPLACE(@str, '√∫', '˙')
	SET @str = REPLACE(@str, '¬∫', '∫')
    SET @str = REPLACE(@str, '√±', 'Ò')
	SET @str = REPLACE(@str, 'Âçò', 'Ò')
	SET @str = REPLACE(@str, '√ë', 'Ò')
	SET @str = REPLACE(@str, '√É∫', '˙')
	SET @str = REPLACE(@str, NCHAR(0xC3) + NCHAR(0x81), '¡')
    return @str;
END;	
GO

--Para insertar los datos de los archivos
--Para el .csv:
--Archivo de Catalogo:

CREATE OR ALTER PROCEDURE Carga.CargarCatalogo
    @direccion VARCHAR(255),						-- Par·metro para la ruta del archivo
    @terminator CHAR(1)                             -- Delimitador de campo
AS
BEGIN
	PRINT 'Procesando Catalogo de Productos'
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

    ALTER TABLE ##CatalogoTemp ADD IdCategoria INT;					--AÒade IdCategoria para usarlo luego en la comparaciÛn

	UPDATE ##CatalogoTemp
	SET Nombre = REPLACE(Nombre, NCHAR(0x5358), 'Ò')				--Corrige errores por la —

	UPDATE ##CatalogoTemp
	SET Nombre = REPLACE(Nombre, '√∫', '˙')
	WHERE Nombre LIKE '%√∫%'

    UPDATE ct SET ct.IdCategoria = cp.Id							--AÒade el valor de IdCategoria al Producto
    FROM ##CatalogoTemp ct
        JOIN Productos.CategoriaDeProds cp ON cp.Producto = ct.Categoria

    INSERT INTO Productos.Catalogo(Nombre,Precio,Proveedor,IdCategoria, PrecioRef, UnidadRef)	 --Inserta al catalogo si no est· el mismo nombre ni la categoria
    SELECT ct.Nombre, ct.Precio, '-' AS Proveedor, ct.IdCategoria, ct.Precio_Ref, ct.Unidad_Ref
    FROM ##CatalogoTemp ct
    WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo c 
                      WHERE c.Nombre = ct.Nombre AND c.IdCategoria = ct.IdCategoria)

	PRINT 'Actualizando precios de catalogo'
	UPDATE Productos.Catalogo
	SET c.Precio = ct.Precio
	FROM Productos.Catalogo	c
	JOIN ##CatalogoTemp ct on c.Nombre = ct.Nombre AND c.Precio <> ct.Precio

    DROP TABLE ##CatalogoTemp

END;
GO

--Archivo de Ventas_registradas:									
CREATE OR ALTER PROCEDURE Carga.CargarHistorialTemp
    @direccion VARCHAR(255),
    @terminator CHAR(1)
AS
BEGIN
	PRINT 'Cargando Historial de Facturas'
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

CREATE OR ALTER PROCEDURE Carga.CargarFacturasDesdeHistorial
AS
BEGIN
	UPDATE ##HistorialTemp
	SET Producto = Ajustes.ArreglarLetras(Producto)

	PRINT 'Cargando facturas viejas en facturas nuevas'
	
	INSERT INTO Ventas.Facturas(IdViejo, TipoFactura, Fecha, Hora, IdMedioPago, Empleado, IdSucursal, IdCliente)
	SELECT h.IdFactura,h.TipoFactura,h.Fecha,h.Hora,mdp.IdMDP,CAST(h.Empleado AS INT),s.IdSucursal,c.IdCliente
	FROM ##HistorialTemp h
		JOIN Complementario.MediosDePago mdp ON h.MedioPago = mdp.NombreING
		JOIN Sucursal.Sucursales s ON h.Ciudad = s.Ciudad
		JOIN Ventas.Clientes c ON c.Genero = h.Genero AND c.TipoCliente = h.TipoCliente

	WHERE h.IdFactura NOT IN (SELECT IdViejo FROM Ventas.Facturas)

	PRINT 'Cargando detalles de ventas'

	DECLARE @ValorDolar DECIMAL(6,2)
	SELECT @ValorDolar = d.PrecioAR FROM Complementario.ValorDolar d
	
	INSERT INTO Ventas.DetalleVentas(IdFactura, IdProducto, Cantidad, PrecioUnitario, IdCategoria)
	SELECT f.IdFactura,c.Id,CAST(h.Cantidad AS INT),CAST(h.PrecioUni * @ValorDolar AS DECIMAL(10, 2)),C.IdCategoria 
	FROM ##HistorialTemp h
		JOIN Ventas.Facturas f on f.IdViejo = h.IdFactura
		CROSS APPLY (
				SELECT TOP 1 * FROM Productos.Catalogo C 
				WHERE C.Nombre = h.Producto AND CAST(h.PrecioUni * @ValorDolar AS DECIMAL(10, 2)) = C.Precio
		) c
	
	WHERE f.IdFactura NOT IN (SELECT IdFactura FROM Ventas.DetalleVentas)

END;
GO

--Para los .xlsx:
--Archivo de Productos_importados:
CREATE OR ALTER PROCEDURE Carga.CargarImportados
    @direccion VARCHAR(100)  
AS
BEGIN
	PRINT 'Procesando Productos Importados'
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
        CAST([CategorÌa] AS VARCHAR(50)),
        CAST(CantidadPorUnidad AS VARCHAR(50)),
        TRY_CAST(REPLACE(REPLACE(PrecioUnidad, ''$'', ''''), '' '', '''') AS DECIMAL(6,2))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.16.0'',
        ''Excel 12.0 Xml; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [Listado de Productos$]''
    ) AS a;';

    EXEC sp_executesql @sql;
	SET NOCOUNT OFF
	PRINT 'Agregando categorias de productos importados'
    INSERT INTO Productos.CategoriaDeProds(LineaDeProducto, Producto)	--Inserta la Categoria del archivo en el tabla de Categorias
    SELECT DISTINCT i.Categoria, i.Nombre
    FROM #ProductosImportados i
    WHERE NOT EXISTS (SELECT 1 FROM Productos.CategoriaDeProds c 
					  WHERE c.LineaDeProducto = i.Categoria AND c.Producto = i.Nombre);
	PRINT 'Agregando productos importados al catalogo'
    INSERT INTO Productos.Catalogo(Nombre, Precio, Proveedor, IdCategoria)	--Inserta en el Catalogo si no tiene el mismo nombre ni IdCategoria
    SELECT i.Nombre,i.PrecioUnidad,i.Proveedor,cp.Id
    FROM #ProductosImportados i 
		JOIN Productos.CategoriaDeProds cp ON cp.LineaDeProducto = i.Categoria AND cp.Producto = i.Nombre
    WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo c
					  WHERE c.Nombre = i.Nombre AND c.IdCategoria = cp.Id);

	PRINT 'Actualizando precios productos importados'
	UPDATE Productos.Catalogo
	SET Precio = p.PrecioUnidad
	FROM Productos.Catalogo	c
	JOIN #ProductosImportados p on c.Nombre = p.Nombre AND c.Precio <> p.PrecioUnidad

    DROP TABLE #ProductosImportados;

END;
GO

--Archivo de Electronic Accessories:
CREATE OR ALTER PROCEDURE Carga.CargarElectronic
    @direccion VARCHAR(100)
AS
BEGIN
	PRINT 'Procesando Accesorios Electronicos'
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
	SET NOCOUNT OFF

    IF NOT EXISTS (SELECT 1 FROM Productos.CategoriaDeProds WHERE LineaDeProducto = 'Accesorios Electronicos')
    BEGIN
		PRINT 'Agregando Categoria de accesorios electronicos'
        INSERT INTO Productos.CategoriaDeProds (LineaDeProducto, Producto)		--Agrega la Categoria a la tabla de Categorias
        VALUES ('Accesorios Electronicos', 'Accesorios Electronicos');
    END;

    DECLARE @IdCategoria INT;														--Obtiene el Id de la categoria
    SELECT @IdCategoria = c.Id 
		FROM Productos.CategoriaDeProds c
		WHERE c.LineaDeProducto = 'Accesorios Electronicos';
	PRINT 'Insertando accesorios electronicos al catalogo'
    INSERT INTO Productos.Catalogo(Nombre, Precio, Proveedor, IdCategoria)			--Inserta en el catalogo si no est·
    SELECT ea.Nombre,ea.PrecioUSD,'-' AS Proveedor,@IdCategoria
    FROM #ElectronicAccessories ea
	WHERE NOT EXISTS (SELECT 1 FROM Productos.Catalogo C 
					  WHERE C.Nombre = ea.Nombre);

	PRINT 'Actualizando precios Accesorios Electronicos'
	UPDATE Productos.Catalogo
	SET Precio = ea.PrecioUSD
	FROM Productos.Catalogo	c
	JOIN #ElectronicAccessories ea on c.Nombre = ea.Nombre AND c.Precio <> ea.PrecioUSD

	DROP TABLE #ElectronicAccessories;

END;
GO

--Archivo Informacion_Complementaria / Medios de pago:
CREATE OR ALTER PROCEDURE Carga.CargarMediosDePago
    @direccion VARCHAR(100)       
AS
BEGIN
	PRINT 'Procesando Medios de Pago'
	SET NOCOUNT ON
	DROP TABLE IF EXISTS #MediosDePagoTemp
	CREATE TABLE #MediosDePagoTemp (
    NombreING VARCHAR(15),
    NombreESP VARCHAR(25)
	);

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO #MediosDePagoTemp (NombreING, NombreESP)
    SELECT 
        CAST(F2 AS VARCHAR(15)),
		CAST(F3 AS VARCHAR(25))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + ';'', 
        ''SELECT * FROM [medios de pago$]''
    );';

    EXEC sp_executesql @sql;

	SET NOCOUNT OFF

    INSERT INTO Complementario.MediosDePago (NombreING, NombreESP)		--Inserta la categoria a la tabla final si no est·
    SELECT mdpt.NombreING, mdpt.NombreESP
    FROM #MediosDePagoTemp mdpt
    WHERE NOT EXISTS (SELECT 1 FROM Complementario.MediosDePago mdp
                      WHERE mdp.NombreING = mdpt.NombreING AND mdp.NombreESP = mdpt.NombreESP);

    DROP TABLE #MediosDePagoTemp;

END;
GO

--Archivo Informacion_Complementaria / Clasificacion Productos:
CREATE OR ALTER PROCEDURE Carga.CargarClasificacion
    @direccion VARCHAR(100)       
AS
BEGIN
	PRINT 'Procesando Clasificacion de Productos'
    SET NOCOUNT ON
   
	DROP TABLE IF EXISTS #ClasificacionTemp
	CREATE TABLE #ClasificacionTemp (
    LineaDeProducto VARCHAR(100),
    Producto VARCHAR(100)
	)

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO #ClasificacionTemp (LineaDeProducto, Producto)
    SELECT 
        CAST([LÌnea de producto] AS VARCHAR(100)),
        CAST(Producto AS VARCHAR(100))
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [Clasificacion productos$]''
    );';

    EXEC sp_executesql @sql

	SET NOCOUNT OFF

    INSERT INTO Productos.CategoriaDeProds (LineaDeProducto, Producto)		--Inserta la categoria a la tabla final si no est·
    SELECT ct.LineaDeProducto,ct.Producto
    FROM #ClasificacionTemp ct
    WHERE NOT EXISTS (SELECT 1 FROM Productos.CategoriaDeProds c
                      WHERE c.LineaDeProducto = ct.LineaDeProducto AND c.Producto = ct.Producto);

    DROP TABLE #ClasificacionTemp;

END;
GO

--Archivo Informacion_Complementaria / Empleados:
CREATE OR ALTER PROCEDURE Carga.CargarEmpleados
    @direccion VARCHAR(100)       
AS
BEGIN
	PRINT 'Procesando Empleados'
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

	SET NOCOUNT OFF
	
	--Inserta el Empleado en la tabla final si no est·
    INSERT INTO Sucursal.Empleados (Legajo, Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo,IdSucursal, Turno, EstaActivo)
    SELECT e.Legajo,e.Nombre,e.Apellido,e.DNI,e.Direccion,e.EmailPersonal,e.EmailEmpresa,e.CUIL,e.Cargo,s.IdSucursal,e.Turno,e.EstaActivo
    FROM #EmpleadosTemp e
		JOIN Sucursal.Sucursales s on s.ReemplazarPor = e.Sucursal
    WHERE NOT EXISTS (SELECT 1 FROM Sucursal.Empleados c WHERE c.Legajo = e.Legajo);

    DROP TABLE #EmpleadosTemp;

END;
GO

CREATE OR ALTER PROCEDURE Carga.CargarSucursales
    @direccion VARCHAR(100)
AS
BEGIN
	PRINT 'Procesando Sucursales'
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

    SET NOCOUNT OFF;


    INSERT INTO Sucursal.Sucursales (Ciudad, ReemplazarPor, Direccion, Horario, Telefono)
    SELECT st.Ciudad, st.ReemplazarPor, st.Direccion, st.Horario, st.Telefono
    FROM #SucursalesTemp st																	--Inserta la sucursal si no est·
    WHERE NOT EXISTS (SELECT 1 FROM Sucursal.Sucursales s
					  WHERE s.Ciudad = st.Ciudad AND s.ReemplazarPor = st.ReemplazarPor
					  AND s.Direccion = st.Direccion);

    DROP TABLE #SucursalesTemp;
END;
GO

-------------SP'S para el Valor Actual del Dolar:
CREATE OR ALTER PROCEDURE Ajustes.CargarValorDolar
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para manejar la respuesta de la API
    DECLARE @url NVARCHAR(64) = 'https://dolarapi.com/v1/dolares/blue'; -- URL del API
    DECLARE @Object INT; -- Objeto para la llamada HTTP
    DECLARE @json TABLE(DATA NVARCHAR(MAX)); -- Tabla para almacenar la respuesta
    DECLARE @respuesta NVARCHAR(MAX); -- Variable para almacenar el JSON de la respuesta
    DECLARE @Venta DECIMAL(6,2); -- Variable para almacenar el valor de venta del dÛlar

    -- Crea el objeto para la llamada HTTP
    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;

    -- Realiza la solicitud GET al API
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';
    EXEC sp_OAMethod @Object, 'SEND';
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT;

    -- Inserta la respuesta del JSON en la tabla temporal
    INSERT INTO @json
    EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';

    -- Extraer el valor de "venta" del JSON
    SELECT @Venta = JSON_VALUE(DATA, '$.venta') FROM @json;

    -- Actualiza el valor del dÛlar en la tabla
    UPDATE Complementario.ValorDolar
    SET PrecioAR = @Venta, FechaHora = SYSDATETIME()
    WHERE FechaHora = (SELECT MAX(FechaHora) FROM Complementario.ValorDolar);

    -- Si no se actualizÛ ninguna fila, inserta un nuevo registro
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO Complementario.ValorDolar (PrecioAR, FechaHora)
        VALUES (@Venta, SYSDATETIME());
    END

    -- Limpia el objeto COM
    EXEC sp_OADestroy @Object;

END;
GO

-------------SP para pasar a pesos los precios:

CREATE OR ALTER PROCEDURE Ajustes.PesificarPrecios
AS
BEGIN
    DECLARE @PrecioDolar DECIMAL(6,2);

    SELECT @PrecioDolar = PrecioAR
    FROM Complementario.ValorDolar

    UPDATE Productos.Catalogo
    SET Precio = Precio * @PrecioDolar;
END;
GO