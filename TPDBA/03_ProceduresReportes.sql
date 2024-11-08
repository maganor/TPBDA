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


DECLARE @xml XML;
EXEC Reportes.GenerarReporteMensual @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;

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

DECLARE @xml XML;
EXEC Reportes.GenerarReportePorRangoFechas @FechaInicio = '2019-01-01', @FechaFin = '2019-03-31', @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;

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

DECLARE @xml XML;
EXEC Reportes.GenerarReportePorRangoFechasSucursal @FechaInicio = '2019-01-01', @FechaFin = '2019-03-31', @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;

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

DECLARE @xml XML;
EXEC Reportes.Top5ProductosPorSemana @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;

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


DECLARE @xml XML;
EXEC Reportes.Menor5ProductosPorMes @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;

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

DECLARE @xml XML;
EXEC Reportes.TotalAcumuladoVentas @Fecha = '2019-03-15', @Sucursal = 'Ramos Mejia', @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;

----------------
--para probrar, dsp borrar
CREATE OR ALTER PROCEDURE Reportes.GenerarReporteTrimestral 
    @FechaInicio DATE,
    @FechaFin DATE,
    @XMLResultado XML OUTPUT
AS
BEGIN
    DECLARE @TempXML XML;

    -- Generación del reporte de ventas para el rango de fechas, agrupado por mes y turno
    SELECT 
        FORMAT(F.Fecha, 'MM-yyyy') AS Mes,  -- Formato de mes y año
        CASE 
            WHEN DATEPART(HOUR, F.Hora) >= 8 AND DATEPART(HOUR, F.Hora) < 14 THEN 'Mañana'  -- Turno Mañana
            WHEN DATEPART(HOUR, F.Hora) >= 14 AND DATEPART(HOUR, F.Hora) <= 21 THEN 'Tarde'   -- Turno Tarde
        END AS Turno,  -- Asignar turno según la hora
        SUM(F.Cantidad * P.Precio * ME.PrecioAR) AS TotalFacturado  -- Convertir precio a ARS usando el valor del dólar
    FROM 
        Ventas.Facturas F
    INNER JOIN 
        Productos.Catalogo P ON F.IdProducto = P.Id
    INNER JOIN 
        Complementario.MonedaExtranjera ME ON ME.Nombre = 'USD'  -- Obtener el valor del USD
    WHERE 
        F.Fecha >= @FechaInicio  -- Filtrar por la fecha de inicio
        AND F.Fecha <= @FechaFin  -- Filtrar por la fecha de fin
    GROUP BY 
        FORMAT(F.Fecha, 'MM-yyyy'),  -- Agrupar por mes y año
        CASE 
            WHEN DATEPART(HOUR, F.Hora) >= 8 AND DATEPART(HOUR, F.Hora) < 14 THEN 'Mañana'  -- Turno Mañana
            WHEN DATEPART(HOUR, F.Hora) >= 14 AND DATEPART(HOUR, F.Hora) <= 21 THEN 'Tarde'   -- Turno Tarde
        END  -- Agrupar también por turno
    FOR XML PATH('Venta'), ROOT('ReporteTrimestralxTurno');  -- Generar el XML

    SET @XMLResultado = @TempXML;  -- Asignar el resultado final a la variable de salida
END;
GO

DECLARE @XMLResultado XML;
EXEC Reportes.GenerarReporteTrimestral 
    @FechaInicio = '2019-01-01',  -- Fecha de inicio
    @FechaFin = '2019-03-31',     -- Fecha de fin
    @XMLResultado = @XMLResultado;




