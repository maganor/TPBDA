
----REPORTES XML (Los nuevos que hay que revisar y probar estan desde la linea 239)

USE Com5600G01
GO

DROP SCHEMA IF EXISTS Reportes
GO
CREATE SCHEMA Reportes
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReporteMensual
    @Mes INT,
    @Anio INT,
    @XMLResultado XML OUTPUT
AS
BEGIN
    SET DATEFIRST 1;

    SELECT 
        @Mes AS Mes,
        @Anio AS Año,
        (
            SELECT 
                DATENAME(WEEKDAY, f.Fecha) AS Nombre,
                SUM(c.Precio * f.Cantidad * me.PrecioAR) AS Total  -- Convertir precio a ARS usando el valor del dólar
            FROM 
                Ventas.Facturas AS f
            INNER JOIN 
                Productos.Catalogo AS c ON f.IdProducto = c.Id
            INNER JOIN 
                Complementario.MonedaExtranjera AS me ON me.Nombre = 'USD'  -- Obtener el valor de USD
            WHERE 
                YEAR(f.Fecha) = @Anio AND 
                MONTH(f.Fecha) = @Mes
            GROUP BY 
                DATENAME(WEEKDAY, f.Fecha), 
                DATEPART(WEEKDAY, f.Fecha)
            ORDER BY 
                DATEPART(WEEKDAY, f.Fecha)
            FOR XML PATH('Dia'), TYPE
        ) AS TotalesPorDia
    FOR XML PATH('ReporteMensual'), ROOT('DatosReporte')
END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReporteTrimestral
    @XMLResultado XML OUTPUT
AS
BEGIN
    DECLARE @TempXML XML;

    SELECT 
        FORMAT(F.Fecha, 'MM-yyyy') AS Mes,
        CASE 
            WHEN DATEPART(HOUR, F.Hora) >= 8 AND DATEPART(HOUR, F.Hora) < 14 THEN 'Mañana'
            WHEN DATEPART(HOUR, F.Hora) >= 14 AND DATEPART(HOUR, F.Hora) <= 21 THEN 'Tarde'
        END AS Turno,
        SUM(F.Cantidad * P.Precio * ME.PrecioAR) AS TotalFacturado  -- Convertir precio a ARS usando el valor del dólar
    FROM 
        Ventas.Facturas F
    INNER JOIN 
        Productos.Catalogo P ON F.IdProducto = P.Id
    INNER JOIN 
        Complementario.MonedaExtranjera ME ON ME.Nombre = 'USD'  -- Obtener el valor de USD
    WHERE 
        F.Fecha >= DATEADD(MONTH, -3, GETDATE()) 
        AND F.Fecha < GETDATE()  
    GROUP BY 
        FORMAT(F.Fecha, 'MM-yyyy'),
        CASE 
            WHEN DATEPART(HOUR, F.Hora) >= 8 AND DATEPART(HOUR, F.Hora) < 14 THEN 'Mañana'
            WHEN DATEPART(HOUR, F.Hora) >= 14 AND DATEPART(HOUR, F.Hora) <= 21 THEN 'Tarde'
        END
    FOR XML PATH('Venta'), ROOT('ReporteTrimestralxTurno');

    SET @XMLResultado = @TempXML;
END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReportePorRangoFechas
    @FechaInicio DATE,  -- Parámetro de fecha de inicio
    @FechaFin DATE,     -- Parámetro de fecha de fin
    @XMLResultado XML OUTPUT  -- Parámetro de salida para el XML generado
AS
BEGIN
    SET NOCOUNT ON;

        SELECT 
            P.Nombre AS Producto,
            SUM(F.Cantidad) AS CantidadVendida
        FROM 
            Ventas.Facturas F
        INNER JOIN 
            Productos.Catalogo P ON F.IdProducto = P.Id  -- Relación con la tabla de productos
        WHERE 
            F.Fecha >= @FechaInicio  -- Filtrar por la fecha de inicio
            AND F.Fecha <= @FechaFin  -- Filtrar por la fecha de fin
        GROUP BY 
            P.Nombre  -- Agrupar por nombre de producto
        ORDER BY 
            CantidadVendida DESC  -- Ordenar de mayor a menor por cantidad vendida
        FOR XML PATH('Producto'), ROOT('ReporteVentasxRangoFechas')  -- Formato XML
END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReportePorRangoFechasSucursal
    @FechaInicio DATE,
    @FechaFin DATE,
    @XMLResultado XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

		SELECT 
            S.ReemplazarPor AS Sucursal,
            P.Nombre AS Producto,
            SUM(F.Cantidad) AS CantidadVendida
        FROM Ventas.Facturas F

        INNER JOIN Complementario.Sucursales S ON F.IdSucursal = S.IdSucursal
        INNER JOIN Productos.Catalogo P ON F.IdProducto = P.Id

        WHERE F.Fecha >= @FechaInicio AND F.Fecha <= @FechaFin

        GROUP BY S.ReemplazarPor, P.Nombre  
        ORDER BY CantidadVendida DESC

        FOR XML PATH('Producto'), ROOT('ReportePorRangoFechasSucursal')
END;
GO

CREATE OR ALTER PROCEDURE Reportes.Top5ProductosPorSemana
    @Mes INT,
    @Anio INT,
    @XMLResultado XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    WITH VentasPorSemana AS (
        SELECT 
            P.Nombre AS Producto,
            DATEPART(WEEK, F.Fecha) AS Semana,
            SUM(F.Cantidad) AS CantidadVendida
        FROM 
            Ventas.Facturas F
        INNER JOIN 
            Productos.Catalogo P ON F.IdProducto = P.Id  -- Relaciona con la tabla de productos
        WHERE 
            MONTH(F.Fecha) = @Mes 
            AND YEAR(F.Fecha) = @Anio
        GROUP BY 
            P.Nombre, DATEPART(WEEK, F.Fecha)
    ),
    Top5PorSemana AS (
        SELECT 
            Producto,
            Semana,
            CantidadVendida,
            ROW_NUMBER() OVER (PARTITION BY Semana ORDER BY CantidadVendida DESC) AS RN
        FROM 
            VentasPorSemana
    )
    SELECT 
        Producto,
        Semana,
        CantidadVendida AS TotalCantidadVendida
    FROM 
        Top5PorSemana
    WHERE 
        RN <= 5
    ORDER BY 
        Semana, TotalCantidadVendida DESC
    FOR XML PATH('Producto'), ROOT('Top5ProductosPorSemana');
END;
GO

CREATE OR ALTER PROCEDURE Reportes.Menor5ProductosPorMes
    @Mes INT,
    @Anio INT,
    @XMLResultado XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 5 
        P.Nombre AS Producto,
        SUM(F.Cantidad) AS CantidadVendida,
        SUM(F.Cantidad * P.Precio * ME.PrecioAR) AS TotalVentas  -- Convertir precio a ARS usando el valor del dólar
    FROM 
        Ventas.Facturas F
    INNER JOIN 
        Productos.Catalogo P ON F.IdProducto = P.Id
    INNER JOIN 
        Complementario.MonedaExtranjera ME ON ME.Nombre = 'USD'  -- Obtener el valor de USD
    WHERE 
        MONTH(F.Fecha) = @Mes 
        AND YEAR(F.Fecha) = @Anio
    GROUP BY 
        P.Nombre
    ORDER BY 
        CantidadVendida ASC  
    FOR XML PATH('Producto'), ROOT('Menor5ProductosPorMes');
END;
GO

CREATE OR ALTER PROCEDURE Reportes.TotalAcumuladoVentas
    @Fecha DATE,               -- Parámetro para la fecha específica
    @Sucursal VARCHAR(100),    -- Parámetro para la sucursal
    @XMLResultado XML OUTPUT   -- Parámetro de salida para el XML generado
AS
BEGIN
    SET NOCOUNT ON;

    -- Generación del reporte de ventas totales para una fecha específica
    SELECT 
        P.Nombre AS Producto,
        SUM(F.Cantidad * P.Precio * ME.PrecioAR) AS TotalVentas  -- Conversión a ARS usando el valor del dólar
    FROM 
        Ventas.Facturas F
    INNER JOIN 
        Productos.Catalogo P ON F.IdProducto = P.Id
    INNER JOIN 
        Complementario.Sucursales S ON F.IdSucursal = S.IdSucursal
    INNER JOIN 
        Complementario.MonedaExtranjera ME ON ME.Nombre = 'USD'  -- Obtener el valor del USD
    WHERE 
        F.Fecha = @Fecha  -- Filtrar por la fecha específica
        AND S.ReemplazarPor = @Sucursal  -- Filtrar por la sucursal
    GROUP BY 
        P.Nombre  -- Agrupar por nombre de producto
	FOR XML PATH('Producto'), ROOT('TotalAcumuladoVentas')  -- Formato XML
END;
GO


----Reportes adaptados a las nuevas tablas (FALTA REVISARLOS Y PROBARLOS  
----ME FALTAN LOS EXEC, NO SE SI FUNCIONARAN LOS QUE ESTAN EN TESTING, EN TODO CASO GENERAR OTROS)

CREATE OR ALTER PROCEDURE Reportes.GenerarReporteMensual
    @Mes INT,
    @Anio INT,
    @XMLResultado XML OUTPUT
AS
BEGIN
    DECLARE @ValorDolar DECIMAL(6,2); 
    SELECT @ValorDolar = PrecioAR FROM Complementario.ValorDolar;

    SET DATEFIRST 1;

    SELECT 
        @Mes AS Mes,
        @Anio AS Año,
        (
            SELECT DATENAME(WEEKDAY, f.Fecha) AS Nombre,SUM(dv.PrecioUnitario * dv.Cantidad * @ValorDolar) AS Total
            FROM Ventas.Facturas AS f
				JOIN Ventas.DetalleVentas AS dv ON f.IdFactura = dv.IdFactura
            WHERE YEAR(f.Fecha) = @Anio AND MONTH(f.Fecha) = @Mes
            
			GROUP BY DATENAME(WEEKDAY, f.Fecha),DATEPART(WEEKDAY, f.Fecha)
			ORDER BY DATEPART(WEEKDAY, f.Fecha)
            
			FOR XML PATH('Dia'), TYPE
        ) AS TotalesPorDia
    
	FOR XML PATH('ReporteMensual'), ROOT('DatosReporte')

END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReporteTrimestral
    @XMLResultado XML OUTPUT
AS
BEGIN
    DECLARE @ValorDolar DECIMAL(6,2);
    SELECT @ValorDolar = PrecioAR FROM Complementario.ValorDolar;

    DECLARE @TempXML XML;

    SELECT 
        FORMAT(F.Fecha, 'MM-yyyy') AS Mes,
        CASE 
            WHEN DATEPART(HOUR, F.Hora) >= 8 AND DATEPART(HOUR, F.Hora) < 14 THEN 'Mañana'
            WHEN DATEPART(HOUR, F.Hora) >= 14 AND DATEPART(HOUR, F.Hora) <= 21 THEN 'Tarde'
        END AS Turno,
        SUM(dv.PrecioUnitario * dv.Cantidad * @ValorDolar) AS TotalFacturado
    
	FROM Ventas.Facturas F
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura
    WHERE F.Fecha >= DATEADD(MONTH, -3, GETDATE()) AND F.Fecha < GETDATE()
    
	GROUP BY 
        FORMAT(F.Fecha, 'MM-yyyy'),
        CASE 
            WHEN DATEPART(HOUR, F.Hora) >= 8 AND DATEPART(HOUR, F.Hora) < 14 THEN 'Mañana'
            WHEN DATEPART(HOUR, F.Hora) >= 14 AND DATEPART(HOUR, F.Hora) <= 21 THEN 'Tarde'
        END
    
	FOR XML PATH('Venta'), ROOT('ReporteTrimestralxTurno');

    SET @XMLResultado = @TempXML;
END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReportePorRangoFechas
    @FechaInicio DATE,
    @FechaFin DATE,
    @XMLResultado XML OUTPUT
AS
BEGIN
    SELECT c.Nombre AS Producto, SUM(dv.Cantidad) AS CantidadVendida
    FROM Ventas.Facturas F
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura
		JOIN Productos.Catalogo c ON dv.IdProducto = c.Id
    
	WHERE F.Fecha >= @FechaInicio AND F.Fecha <= @FechaFin
    
	GROUP BY c.Nombre
    ORDER BY  CantidadVendida DESC

    FOR XML PATH('Producto'), ROOT('ReporteVentasxRangoFechas')

END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReportePorRangoFechasSucursal
    @FechaInicio DATE,
    @FechaFin DATE,
    @XMLResultado XML OUTPUT
AS
BEGIN
    SELECT s.reemplazarpor AS Sucursal, c.Nombre AS Producto,SUM(dv.Cantidad) AS CantidadVendida
    FROM Ventas.Facturas F
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura
		JOIN Complementario.Sucursales s ON F.IdSucursal = s.IdSucursal
		JOIN Productos.Catalogo c ON dv.IdProducto = c.Id

    WHERE F.Fecha >= @FechaInicio AND F.Fecha <= @FechaFin
    
	GROUP BY s.reemplazarpor, c.Nombre
    ORDER BY CantidadVendida DESC

    FOR XML PATH('Producto'), ROOT('ReportePorRangoFechasSucursal')

END;
GO

CREATE OR ALTER PROCEDURE Reportes.Top5ProductosPorSemana
    @Mes INT,
    @Anio INT,
    @XMLResultado XML OUTPUT
AS
BEGIN
    WITH VentasPorSemana AS (
        SELECT c.Nombre AS Producto,DATEPART(WEEK, F.Fecha) AS Semana,SUM(dv.Cantidad) AS CantidadVendida
        FROM Ventas.Facturas F
			JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura
			JOIN Productos.Catalogo c ON dv.IdProducto = c.Id
        
		WHERE MONTH(F.Fecha) = @Mes AND YEAR(F.Fecha) = @Anio
        GROUP BY c.Nombre, DATEPART(WEEK, F.Fecha)
    ),
    Top5PorSemana AS (
        SELECT Producto,Semana,CantidadVendida,ROW_NUMBER() OVER (PARTITION BY Semana ORDER BY CantidadVendida DESC) AS RN
        FROM VentasPorSemana
    )
    SELECT Producto,Semana,CantidadVendida AS TotalCantidadVendida
    FROM Top5PorSemana
    
	WHERE RN <= 5
    ORDER BY Semana, TotalCantidadVendida DESC
    
	FOR XML PATH('Producto'), ROOT('Top5ProductosPorSemana')

END;
GO

CREATE OR ALTER PROCEDURE Reportes.Menor5ProductosPorMes
    @Mes INT,
    @Anio INT,
    @XMLResultado XML OUTPUT
AS
BEGIN
    SELECT TOP 5 c.Nombre AS Producto, SUM(dv.Cantidad) AS CantidadVendida
    FROM Ventas.Facturas F
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura
		JOIN Productos.Catalogo c ON dv.IdProducto = c.Id
    
	WHERE MONTH(F.Fecha) = @Mes AND YEAR(F.Fecha) = @Anio
    
	GROUP BY c.Nombre
    ORDER BY CantidadVendida ASC

    FOR XML PATH('Producto'), ROOT('Menor5ProductosPorMes')

END;
GO

CREATE OR ALTER PROCEDURE Reportes.TotalAcumuladoVentas
    @Fecha DATE,
    @Sucursal VARCHAR(100),
    @XMLResultado XML OUTPUT
AS
BEGIN
    DECLARE @ValorDolar DECIMAL(6,2);
	SELECT @ValorDolar = PrecioAR FROM Complementario.ValorDolar;

    SELECT c.Nombre AS Producto, SUM(dv.Cantidad * dv.PrecioUnitario * @ValorDolar) AS TotalVentas
    FROM Ventas.Facturas F
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura
		JOIN Productos.Catalogo c ON dv.IdProducto = c.Id
		JOIN Complementario.Sucursales s ON F.IdSucursal = s.IdSucursal
		
	WHERE F.Fecha = @Fecha AND s.reemplazarpor = @Sucursal 

    GROUP BY c.Nombre

    FOR XML PATH('Producto'), ROOT('TotalAcumuladoVentas')

END;
GO
