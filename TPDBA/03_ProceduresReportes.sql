
--Trabajo Practico Integrador - Bases de Datos Aplicada:
--Fecha de Entrega: 15/11/2024
--Comisión: 02-5600
--Grupo: 01
--Integrantes:
--Antola Ortiz, Mauricio Gabriel  -       44613237 
--Tempra, Francisco               -       44485891
--Villegas Brandolini, Lucas      -       44459666
--Zapata, Santiago                -       44525943

--Consignas que se cumplen:
--El sistema debe ofrecer los siguientes reportes en xml:
--Mensual: ingresando un mes y año determinado mostrar el total facturado por días de la semana, incluyendo sábado y domingo.
--Trimestral: mostrar el total facturado por turnos de trabajo por mes.
--Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango, 
--ordenado de mayor a menor.
--Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar la cantidad de productos vendidos en ese rango 
--por sucursal, ordenado de mayor a menor.
--Mostrar los 5 productos más vendidos en un mes, por semana
--Mostrar los 5 productos menos vendidos en el mes.
--Mostrar total acumulado de ventas (o sea tambien mostrar el detalle) para una fecha y sucursal particulares
----REPORTES XML:

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
    SET LANGUAGE Spanish;	-- Para mostrar los nombres de los dias en español
	SET DATEFIRST 1;		-- Se establece Lunes como 1

    SELECT 
        @Mes AS Mes,
        @Anio AS Año,
        (
            SELECT DATENAME(WEEKDAY, f.Fecha) AS Nombre,						-- Nombre del día de la semana
				   SUM(dv.PrecioUnitario * dv.Cantidad) AS Total				-- Suma total de facturación del día
            
			FROM Ventas.Facturas AS f
				JOIN Ventas.DetalleVentas AS dv ON f.IdFactura = dv.IdFactura	-- Obtiene el total facturado
            
			WHERE YEAR(f.Fecha) = @Anio AND MONTH(f.Fecha) = @Mes			-- Filtra por año y mes enviado
            
			GROUP BY DATENAME(WEEKDAY, f.Fecha),DATEPART(WEEKDAY, f.Fecha)	-- Obtiene el nombre del dia para mostrar, Obtiene el numero que sirve para ordenar
			ORDER BY DATEPART(WEEKDAY, f.Fecha)								-- Ordena por dia de la semana
            
			FOR XML PATH('Dia'), TYPE
        ) AS TotalesPorDia
    
	FOR XML PATH('ReporteMensual'), ROOT('DatosReporte')

END;
GO

CREATE OR ALTER PROCEDURE Reportes.GenerarReporteTrimestral
    @XMLResultado XML OUTPUT
AS
BEGIN
    SELECT FORMAT(F.Fecha, 'MM-yyyy') AS Mes,
        CASE																					--Para determinar el turno segun la hora
            WHEN DATEPART(HOUR, F.Hora) >= 8 AND DATEPART(HOUR, F.Hora) < 14 THEN 'Mañana'
            WHEN DATEPART(HOUR, F.Hora) >= 14 AND DATEPART(HOUR, F.Hora) <= 21 THEN 'Tarde'
        END AS Turno,
        SUM(dv.PrecioUnitario * dv.Cantidad) AS TotalFacturado
    
	FROM Ventas.Facturas F
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura

    WHERE F.Fecha >= DATEADD(MONTH, -3, GETDATE()) AND F.Fecha < GETDATE()	--Filtra las facturas de los ultimos 3 meses
    
	GROUP BY FORMAT(F.Fecha, 'MM-yyyy'),									--Agrupa por mes y turno
        CASE 
            WHEN DATEPART(HOUR, F.Hora) >= 8 AND DATEPART(HOUR, F.Hora) < 14 THEN 'Mañana'
            WHEN DATEPART(HOUR, F.Hora) >= 14 AND DATEPART(HOUR, F.Hora) <= 21 THEN 'Tarde'
        END
    
	FOR XML PATH('Venta'), ROOT('ReporteTrimestralxTurno');

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
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura		-- Unión para obtener las cantidades vendidas
		JOIN Productos.Catalogo c ON dv.IdProducto = c.Id				-- Unión para obtener el nombre del producto
    
	WHERE F.Fecha >= @FechaInicio AND F.Fecha <= @FechaFin				-- Filtrado por las fechas recibidas
    
	GROUP BY c.Nombre
    ORDER BY CantidadVendida DESC

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
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura		-- Unión para obtener las cantidades vendidas
		JOIN Sucursal.Sucursales s ON F.IdSucursal = s.IdSucursal	-- Unión para obtener el nombre de la sucursal
		JOIN Productos.Catalogo c ON dv.IdProducto = c.Id				-- Unión para obtener el nombre del producto

    WHERE F.Fecha >= @FechaInicio AND F.Fecha <= @FechaFin				-- Filtrado por las fechas recibidas
    
	GROUP BY s.reemplazarpor, c.Nombre									-- Agrupa por sucursal y producto
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
    -- Se calcula la cantidad total vendida de cada producto por semana dentro del mes y año recibido
	WITH VentasPorSemana AS (
        SELECT c.Nombre AS Producto,DATEPART(WEEK, F.Fecha) AS Semana,SUM(dv.Cantidad) AS CantidadVendida
        FROM Ventas.Facturas F
			JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura
			JOIN Productos.Catalogo c ON dv.IdProducto = c.Id
        
		WHERE MONTH(F.Fecha) = @Mes AND YEAR(F.Fecha) = @Anio	
        GROUP BY c.Nombre, DATEPART(WEEK, F.Fecha)
    ),
	-- Se calcula el ranking de productos por semana para cada semana
    Top5PorSemana AS (
        SELECT Producto,Semana,CantidadVendida,ROW_NUMBER() OVER (PARTITION BY Semana ORDER BY CantidadVendida DESC) AS Ranking
        FROM VentasPorSemana
    )
    -- Se seleccionan los 5 productos más vendidos por semana
	SELECT Producto,Semana,CantidadVendida AS TotalCantidadVendida FROM Top5PorSemana
	WHERE Ranking <= 5
    ORDER BY Semana, TotalCantidadVendida DESC
    
	FOR XML PATH('Producto'), ROOT('Top5ProductosPorSemana')

END;
GO

CREATE OR ALTER PROCEDURE Reportes.MenosVendidosPorMes
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
    SELECT c.Nombre AS Producto, SUM(dv.Cantidad * dv.PrecioUnitario) AS TotalVentas
    FROM Ventas.Facturas F
		JOIN Ventas.DetalleVentas dv ON F.IdFactura = dv.IdFactura			-- Se obtiene la cantidad y el precio
		JOIN Productos.Catalogo c ON dv.IdProducto = c.Id					-- Se obtiene el nombre del producto
		JOIN Sucursal.Sucursales s ON F.IdSucursal = s.IdSucursal		-- Se obtiene la sucursal
		
	WHERE F.Fecha = @Fecha AND s.reemplazarpor = @Sucursal					-- Filtrado por fecha y sucursal recibida

    GROUP BY c.Nombre

    FOR XML PATH('Producto'), ROOT('TotalAcumuladoVentas')

END;
GO
