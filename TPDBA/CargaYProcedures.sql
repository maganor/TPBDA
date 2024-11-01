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
	Id, Tipo_Factura, Ciudad, Tipo_Cliente, Genero, [Linea de Producto], Producto, PrecioUni, Cantidad, Fecha, Hora, MedioPago, Empleado, Sucursal
    )
    SELECT 
        h.Id,
        h.Tipo_Factura,
        h.Ciudad,
        h.Tipo_Cliente,
        h.Genero,        
        '-' AS [Linea de Producto],
		h.Producto, 
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
        Complementario.Sucursales AS s ON h.Ciudad = s.Ciudad;              
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.Agregar_Factura
	@cantidad INT,
	@tipoCliente CHAR(6),
	@genero CHAR,
	@empleado INT,
	@tipoFactura CHAR,
	@medioDePago CHAR(11),
	@producto VARCHAR(100),
	@ciudad VARCHAR(15),
	@id CHAR(11)
AS
BEGIN
	DECLARE @Linea_prod VARCHAR(11)
	DECLARE @sucursal VARCHAR(17)
	DECLARE @precio DECIMAL(6,2)

	-- VERIFICAR EXISTENCIA EMPLEADO
	-- VERIFICAR EXISTENCIA CIUDAD/PRODUCTO

	SELECT @Linea_prod = [Linea de Producto] from Productos.CatalogoFinal c WHERE c.Nombre = @producto 
	SELECT @sucursal = [Reemplazar por] from Complementario.Sucursales s WHERE s.ciudad = @ciudad 
	SELECT @precio = Precio from Productos.CatalogoFinal c WHERE c.Nombre = @producto

	INSERT INTO Ventas.VtasAReg (Tipo_Factura, Tipo_Cliente, Genero, Cantidad, MedioPago, ciudad, sucursal, [Linea de Producto], Fecha, Hora, Producto, PrecioUni, Id, Empleado)
	VALUES (@tipoFactura, @tipoCliente, @genero, @cantidad, @medioDePago, @ciudad, @sucursal, @Linea_prod, GETDATE(), CAST(SYSDATETIME() AS TIME (0)), @producto, @precio, @id, @empleado)
END;
GO

--Ver procedimientos en esquema 'Procedimientos'
SELECT SCHEMA_NAME(schema_id) AS Esquema, name AS Procedimiento
FROM sys.procedures
WHERE SCHEMA_NAME(schema_id) = 'Procedimientos';
GO

DECLARE @PATH VARCHAR(255) = 'C:\Users\wixde\Desktop\TP_integrador_Archivos'
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

--USE master
--GO
--DROP DATABASE Com5600G01
--GO