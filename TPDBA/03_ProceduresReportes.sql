
----REPORTES XML: (Los nuevos que hay que revisar y probar estan desde la linea 239)

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
