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
    -- Aseguramos que la semana comienza en lunes
    SET DATEFIRST 1;

    SET @XMLResultado = (
        SELECT 
            @Mes AS Mes,
            @Anio AS Año,
            (
                SELECT 
                    DATENAME(WEEKDAY, Fecha) AS Nombre,
                    SUM(PrecioUni * Cantidad) AS Total
                FROM 
                    Ventas.VtasAReg
                WHERE 
                    YEAR(Fecha) = @Anio AND 
                    MONTH(Fecha) = @Mes
                GROUP BY 
                    DATENAME(WEEKDAY, Fecha), 
                    DATEPART(WEEKDAY, Fecha)
                ORDER BY 
                    DATEPART(WEEKDAY, Fecha)
                FOR XML PATH('Dia'), TYPE
            ) AS TotalesPorDia
        FOR XML PATH('ReporteMensual'), ROOT('DatosReporte')
    );
END;
GO

DECLARE @xml XML;
EXEC Reportes.GenerarReporteMensual @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;

--CREATE OR ALTER PROCEDURE Reportes.GenerarReporteTrimestral
--    @XMLResultado XML OUTPUT
--AS
--BEGIN
--    DECLARE @TempXML XML; -- Variable intermedia para almacenar el resultado XML

--    SELECT 
--        FORMAT(V.Fecha, 'MM-yyyy') AS Mes,
--        CASE 
--            WHEN DATEPART(HOUR, V.Hora) >= 8 AND DATEPART(HOUR, V.Hora) < 14 THEN 'Mañana'
--            WHEN DATEPART(HOUR, V.Hora) >= 14 AND DATEPART(HOUR, V.Hora) < 21 THEN 'Tarde'
--        END AS Turno,
--        SUM(V.PrecioUni * V.Cantidad) AS TotalFacturado
--    FROM 
--        Ventas.VtasAReg V
--    WHERE 
--        V.Fecha >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 3, 0) -- Calcula el inicio de los Últimos 3 meses
--        AND V.Fecha < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- Calcula el fin de los Últimos 3 meses
--    GROUP BY 
--        FORMAT(V.Fecha, 'MM-yyyy'), 
--        CASE 
--            WHEN DATEPART(HOUR, V.Hora) >= 8 AND DATEPART(HOUR, V.Hora) < 14 THEN 'Mañana'
--            WHEN DATEPART(HOUR, V.Hora) >= 14 AND DATEPART(HOUR, V.Hora) < 21 THEN 'Tarde'
--        END
--    FOR XML PATH('Venta'), ROOT('ReporteTrimestralxTurno');

--    SET @XMLResultado = @TempXML; -- Asigna el resultado a la variable de salida
--END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReportePorRangoFechas
    @FechaInicio DATE,  -- Parámetro de fecha de inicio
    @FechaFin DATE,     -- Parámetro de fecha de fin
    @XMLResultado XML OUTPUT  -- Parámetro de salida para el XML generado
AS
BEGIN
    SET NOCOUNT ON;

    -- Generar el XML con la cantidad de productos vendidos en el rango de fechas
    SELECT 
        V.Producto,
        SUM(V.Cantidad) AS CantidadVendida
    FROM 
        Ventas.VtasAReg V
    WHERE 
        V.Fecha >= @FechaInicio  -- Filtrar por la fecha de inicio
        AND V.Fecha <= @FechaFin  -- Filtrar por la fecha de fin
    GROUP BY 
        V.Producto  -- Agrupar por producto
    ORDER BY 
        CantidadVendida DESC  -- Ordenar de mayor a menor por cantidad vendida
    FOR XML PATH('Producto'), ROOT('ReporteVentasxRangoFechas');  -- Formato XML
END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReportePorRangoFechas
    @FechaInicio DATE,  -- Parámetro de fecha de inicio
    @FechaFin DATE,     -- Parámetro de fecha de fin
    @XMLResultado XML OUTPUT  -- Parámetro de salida para el XML generado
AS
BEGIN
    SET NOCOUNT ON;

    -- Generar el XML con la cantidad de productos vendidos en el rango de fechas
    SELECT V.Producto,SUM(V.Cantidad) AS CantidadVendida
    FROM Ventas.VtasAReg V
    WHERE V.Fecha >= @FechaInicio  -- Filtrar por la fecha de inicio
          AND V.Fecha <= @FechaFin  -- Filtrar por la fecha de fin
    GROUP BY V.Producto  -- Agrupar por producto
    ORDER BY CantidadVendida DESC  -- Ordenar de mayor a menor por cantidad vendida
    FOR XML PATH('Producto'), ROOT('ReporteVentasxRangoFechas');  -- Formato XML
END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReportePorRangoFechasSucursal
    @FechaInicio DATE,
    @FechaFin DATE,
    @XMLResultado XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT V.Sucursal,V.Producto,SUM(V.Cantidad) AS CantidadVendida
    FROM Ventas.VtasAReg V
    WHERE V.Fecha >= @FechaInicio AND V.Fecha <= @FechaFin
    GROUP BY V.Sucursal,V.Producto
    ORDER BY CantidadVendida DESC
    FOR XML PATH('Producto'), ROOT('ReportePorRangoFechasSucursal');
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
        SELECT V.Producto,DATEPART(WEEK, V.Fecha) AS Semana,SUM(V.Cantidad) AS CantidadVendida
        FROM Ventas.VtasAReg V
        WHERE MONTH(V.Fecha) = @Mes AND YEAR(V.Fecha) = @Anio
        GROUP BY V.Producto, DATEPART(WEEK, V.Fecha)
    )
    SELECT TOP 5 V.Producto,SUM(V.CantidadVendida) AS TotalCantidadVendida
    FROM VentasPorSemana V
    GROUP BY V.Producto
    ORDER BY TotalCantidadVendida DESC
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

    SELECT TOP 5 V.Producto, SUM(V.Cantidad) AS CantidadVendida
    FROM Ventas.VtasAReg V
    WHERE MONTH(V.Fecha) = @Mes AND YEAR(V.Fecha) = @Anio
    GROUP BY V.Producto
    ORDER BY CantidadVendida ASC
    FOR XML PATH('Producto'), ROOT('Menor5ProductosPorMes');
END;
GO

CREATE OR ALTER PROCEDURE Reportes.TotalAcumuladoVentas
    @Fecha DATE,
    @Sucursal VARCHAR(17),
    @XMLResultado XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT V.Producto, SUM(V.PrecioUni * V.Cantidad) AS TotalVentas
    FROM Ventas.VtasAReg V
    WHERE V.Fecha = @Fecha AND V.Sucursal = @Sucursal
    GROUP BY V.Producto
    FOR XML PATH('Producto'), ROOT('TotalAcumuladoVentas');
END;
GO