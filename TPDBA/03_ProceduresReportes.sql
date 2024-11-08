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

    -- Generamos el XML de salida con el total facturado por día de la semana
    SET @XMLResultado = (
        SELECT 
            @Mes AS Mes,
            @Anio AS Año,
            (
                SELECT 
                    DATENAME(WEEKDAY, f.Fecha) AS Nombre,
                    SUM(c.Precio * f.Cantidad) AS Total
                FROM 
                    Ventas.Facturas AS f
                INNER JOIN 
                    Productos.Catalogo AS c ON f.IdProducto = c.Id
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
    );
END;
GO

DECLARE @xml XML;
EXEC Reportes.GenerarReporteMensual @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;


CREATE OR ALTER PROCEDURE Reportes.GenerarReporteTrimestral
    @XMLResultado XML OUTPUT
AS
BEGIN
    DECLARE @TempXML XML; -- Variable intermedia para almacenar el resultado XML

    -- Generación del reporte de ventas para los últimos tres meses, agrupado por mes y turno
    SELECT 
        FORMAT(F.Fecha, 'MM-yyyy') AS Mes,  -- Formato de mes y año
        CASE 
            WHEN DATEPART(HOUR, F.Fecha) >= 8 AND DATEPART(HOUR, F.Fecha) < 14 THEN 'Mañana'  -- Turno Mañana
            WHEN DATEPART(HOUR, F.Fecha) >= 14 AND DATEPART(HOUR, F.Fecha) < 21 THEN 'Tarde'   -- Turno Tarde
            ELSE 'Noche'  -- Asignación para cualquier otra hora, si corresponde
        END AS Turno,  
        SUM(F.PrecioUni * F.Cantidad) AS TotalFacturado  -- Total facturado (Precio * Cantidad)
    FROM 
        Ventas.Facturas F
    WHERE 
        F.Fecha >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 3, 0)  -- Inicio de los últimos 3 meses
        AND F.Fecha < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)  -- Fin de los últimos 3 meses
    GROUP BY 
        FORMAT(F.Fecha, 'MM-yyyy'),  -- Agrupar por mes y año
        CASE 
            WHEN DATEPART(HOUR, F.Fecha) >= 8 AND DATEPART(HOUR, F.Fecha) < 14 THEN 'Mañana'  -- Turno Mañana
            WHEN DATEPART(HOUR, F.Fecha) >= 14 AND DATEPART(HOUR, F.Fecha) < 21 THEN 'Tarde'   -- Turno Tarde
            ELSE 'Noche'  -- Asignación para cualquier otra hora, si corresponde
        END
    FOR XML PATH('Venta'), ROOT('ReporteTrimestralxTurno');  -- Generar el XML

    SET @XMLResultado = @TempXML;  -- Asignar el resultado final a la variable de salida
END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReportePorRangoFechas
    @FechaInicio DATE,  -- Parámetro de fecha de inicio
    @FechaFin DATE,     -- Parámetro de fecha de fin
    @XMLResultado XML OUTPUT  -- Parámetro de salida para el XML generado
AS
BEGIN
    SET NOCOUNT ON;

    SET @XMLResultado = (
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
    );
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

    SET @XMLResultado = (
        SELECT 
            S.Ciudad AS Sucursal,
            P.Nombre AS Producto,
            SUM(F.Cantidad) AS CantidadVendida
        FROM 
            Ventas.Facturas F
        INNER JOIN 
            Complementario.Sucursales S ON F.IdSucursal = S.IdSucursal  -- Relación con la tabla de sucursales
        INNER JOIN 
            Productos.Catalogo P ON F.IdProducto = P.Id  -- Relación con la tabla de productos
        WHERE 
            F.Fecha >= @FechaInicio 
            AND F.Fecha <= @FechaFin
        GROUP BY 
            S.Ciudad, P.Nombre
        ORDER BY 
            CantidadVendida DESC
        FOR XML PATH('Producto'), ROOT('ReportePorRangoFechasSucursal')  -- Formato XML
    );
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
        SUM(F.Cantidad) AS CantidadVendida
    FROM 
        Ventas.Facturas F
    INNER JOIN 
        Productos.Catalogo P ON F.IdProducto = P.Id  -- Relaciona con la tabla de productos
    WHERE 
        MONTH(F.Fecha) = @Mes 
        AND YEAR(F.Fecha) = @Anio
    GROUP BY 
        P.Nombre
    ORDER BY 
        CantidadVendida ASC  -- Orden ascendente para obtener los menos vendidos
    FOR XML PATH('Producto'), ROOT('Menor5ProductosPorMes');
END;
GO

DECLARE @xml XML;
EXEC Reportes.Menor5ProductosPorMes @Mes = 3, @Anio = 2019, @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;


CREATE OR ALTER PROCEDURE Reportes.TotalAcumuladoVentas
    @Fecha DATE,
    @Sucursal VARCHAR(100),
    @XMLResultado XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.Nombre AS Producto,  -- Obtener el nombre del producto
        SUM(F.PrecioUni * F.Cantidad) AS TotalVentas
    FROM 
        Ventas.Facturas F
    INNER JOIN 
        Productos.Catalogo P ON F.IdProducto = P.Id  -- Relaciona el producto con la tabla Productos.Catalogo
    INNER JOIN 
        Complementario.Sucursales S ON F.IdSucursal = S.IdSucursal  -- Relaciona con Sucursal
    WHERE 
        F.Fecha = @Fecha 
        AND S.Ciudad = @Sucursal  -- Filtra por ciudad en lugar de la sucursal
    GROUP BY 
        P.Nombre
    FOR XML PATH('Producto'), ROOT('TotalAcumuladoVentas');
END;
GO

DECLARE @xml XML;
EXEC Reportes.TotalAcumuladoVentas @Fecha = '2019-03-15', @Sucursal = 'Buenos Aires', @XMLResultado = @xml OUTPUT;
SELECT @xml AS XMLResultado;