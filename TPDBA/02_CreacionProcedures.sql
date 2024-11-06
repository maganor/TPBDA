USE Com5600G01
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

CREATE OR ALTER PROCEDURE Procedimientos.CargarImportados
    @direccion VARCHAR(100),
    @tabla VARCHAR(100),
    @pagina VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    -- Inserta los datos en la tabla temporal global
    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@tabla) + N'
    SELECT 
        CAST(IdProducto AS INT),
        CAST(NombreProducto AS NVARCHAR(100)),
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
	--Inserta los datos en la tabla temporal global
    SET @sql = N'
    INSERT INTO ' + QUOTENAME(@tabla) + N'
    SELECT 
        CAST(Product AS NVARCHAR(100)),
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
        CAST(Turno AS VARCHAR(25)),
		1
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

CREATE OR ALTER PROCEDURE Procedimientos.LlenarCatalogo
AS
BEGIN 
    -- Insertar solo productos nuevos
    INSERT INTO Productos.Catalogo (LineaDeProducto, Nombre, Precio, Proveedor)
    SELECT 
        cdp.LineaDeProducto, 
        c.Nombre, 
        c.Precio, 
        '-' AS Proveedor
    FROM 
        ##CatalogoTemp AS c
    JOIN 
        Complementario.ClasificacionDeProductos AS cdp ON c.Categoria = cdp.Producto
    WHERE c.Nombre NOT IN (SELECT Nombre FROM Productos.Catalogo);

    INSERT INTO Productos.Catalogo(LineaDeProducto, Nombre, Precio, Proveedor)
    SELECT
        'Accesorios Electronicos' AS Categoria,
        e.Nombre,
        e.PrecioUSD,
        '-' AS Proveedor
    FROM
        ##ElectronicAccessories AS e
    WHERE e.Nombre NOT IN (SELECT Nombre FROM Productos.Catalogo);

    INSERT INTO Productos.Catalogo(LineaDeProducto, Nombre, Precio, Proveedor)
    SELECT
        p.Categoria,
        p.Nombre,
        p.PrecioUnidad,
        p.Proveedor
    FROM
        ##ProductosImportados AS p
    WHERE p.Nombre NOT IN (SELECT Nombre FROM Productos.Catalogo);

END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.CargarVentasAReg
AS
BEGIN 
    INSERT INTO Ventas.Facturas (
	Id, TipoFactura, Ciudad, TipoCliente, Genero, LineaDeProducto, Producto, PrecioUni, Cantidad, Fecha, Hora, MedioPago, Empleado, Sucursal
    )
    SELECT 
        h.Id,
        h.TipoFactura,
        h.Ciudad,
        h.TipoCliente,
        h.Genero,        
        '-' AS LineaDeProducto,
		h.Producto, 
        h.PrecioUni,
        h.Cantidad,
        h.Fecha,
        h.Hora,
        h.MedioPago,
        h.Empleado,             
        s.ReemplazarPor 
    FROM 
        ##Historial AS h
    JOIN 
        Complementario.Sucursales AS s ON h.Ciudad = s.Ciudad;              
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.ActualizarPrecioCatalogo  --Probar dsp cuando inventemos datos
AS
BEGIN
	--Para los productos de ##CatalogoTemp
	UPDATE cf
	SET cf.Precio = (SELECT c.Precio from ##CatalogoTemp c where c.Nombre = cf.Nombre)
	FROM Productos.Catalogo cf
	WHERE cf.Nombre IN (SELECT Nombre from ##CatalogoTemp) AND cf.Precio <> (SELECT c.Precio FROM ##CatalogoTemp AS c WHERE c.Nombre = cf.Nombre)
	--Para los productos de ##ElectronicAccessories
	UPDATE cf
	SET cf.Precio = (SELECT e.PrecioUSD FROM ##ElectronicAccessories AS e WHERE e.Nombre = cf.Nombre)
	FROM Productos.Catalogo AS cf
	WHERE cf.LineaDeProducto = 'Accesorios Electronicos' 
    AND cf.Nombre IN (SELECT Nombre FROM ##ElectronicAccessories) 
    AND cf.Precio <> (SELECT e.PrecioUSD FROM ##ElectronicAccessories AS e WHERE e.Nombre = cf.Nombre)
	--Para los productos de ##ProductosImportados
	UPDATE cf
	SET cf.Precio = (SELECT p.PrecioUnidad FROM ##ProductosImportados AS p WHERE p.Nombre = cf.Nombre)
	FROM Productos.Catalogo AS cf
	WHERE cf.LineaDeProducto = (SELECT p.Categoria FROM ##ProductosImportados AS p WHERE p.Nombre = cf.Nombre)
    AND cf.Nombre IN (SELECT Nombre FROM ##ProductosImportados) 
    AND cf.Precio <> (SELECT p.PrecioUnidad FROM ##ProductosImportados AS p WHERE p.Nombre = cf.Nombre)
END;
GO

--Ver procedimientos en esquema 'Procedimientos'
SELECT SCHEMA_NAME(schema_id) AS Esquema, name AS Procedimiento
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'Procedimientos';
GO