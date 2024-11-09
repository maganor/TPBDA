
--Trabajo Practico Integrador - Bases de Datos Aplicada:
--Integrantes:
--Antola Ortiz, Mauricio Gabriel  -       44613237 
--Tempra, Francisco               -       44485891
--Villegas Brandolini, Lucas      -       44459666
--Zapata, Santiago                -       44525943

USE master
GO
DROP DATABASE Com5600G01
GO
CREATE DATABASE Com5600G01
GO

USE Com5600G01
GO

DROP SCHEMA IF EXISTS Productos
GO
CREATE SCHEMA Productos
GO

DROP TABLE IF EXISTS ##CatalogoTemp
GO
CREATE TABLE ##CatalogoTemp(
	Id INT PRIMARY KEY,
	Categoria VARCHAR(100),
	Nombre NVARCHAR(100),
	Precio DECIMAL(6,2),
	Precio_Ref DECIMAL(6,2),
	Unidad_Ref VARCHAR(10),
	Fecha DATETIME
)

DROP TABLE IF EXISTS ##ProductosImportados
GO
CREATE TABLE ##ProductosImportados(
	IdProducto INT PRIMARY KEY,
    Nombre NVARCHAR(100),
    Proveedor VARCHAR(100),
    Categoria VARCHAR(50),
    CantidadPorUnidad VARCHAR(50),
    PrecioUnidad DECIMAL(6,2),
)

DROP TABLE IF EXISTS ##ElectronicAccessories
CREATE TABLE ##ElectronicAccessories(
   Nombre NVARCHAR(100),
   PrecioUSD DECIMAL(6,2)
)

DROP TABLE IF EXISTS Productos.Catalogo
GO
CREATE TABLE Productos.Catalogo(
	Id INT IDENTITY (1,1) PRIMARY KEY,
	LineaDeProducto VARCHAR(100),
	Categoria VARCHAR(100),
	Nombre NVARCHAR(100),
	Precio DECIMAL(6,2),
	Proveedor VARCHAR(100)
)

--Para ver que las tablas pertenezcan al esquema 'Productos'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Productos'
GO

--Se crea este esquema para la info complementaria.
DROP SCHEMA IF EXISTS Complementario
GO
CREATE SCHEMA Complementario
GO

DROP TABLE IF EXISTS Complementario.Empleados
CREATE TABLE Complementario.Empleados(
    Legajo INT PRIMARY KEY,
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
	EstaActivo BIT NOT NULL DEFAULT 1,
	DNI_Cifrado VARBINARY(256),
	Direccion_Cifrada VARBINARY(256),
	EmailPersonal_Cifrado VARBINARY(256),
	CUIL_Cifrado VARBINARY(256)
);
GO

DROP TABLE IF EXISTS Complementario.Sucursales
CREATE TABLE Complementario.Sucursales(
		IdSucursal INT IDENTITY(1,1) PRIMARY KEY,
        Ciudad VARCHAR(100),
        ReemplazarPor VARCHAR(100),
        Direccion VARCHAR(200),
        Horario VARCHAR(100),
        Telefono VARCHAR(20)
);
GO

DROP TABLE IF EXISTS Complementario.ClasificacionDeProductos
CREATE TABLE Complementario.ClasificacionDeProductos (
    LineaDeProducto VARCHAR(100),
    Producto VARCHAR(100)
);
GO

DROP TABLE IF EXISTS Complementario.MonedaExtranjera
CREATE TABLE Complementario.MonedaExtranjera(
	Id INT IDENTITY(1,1) PRIMARY KEY,
	Nombre CHAR(3),
	PrecioAR DECIMAL(6,2)
)
GO

DROP TABLE IF EXISTS Complementario.MediosDePago
CREATE TABLE Complementario.MediosDePago(
	IdMDP INT IDENTITY(1,1) PRIMARY KEY,
	NombreING VARCHAR(15),
	NombreESP VARCHAR(25)
)
GO

--Para ver que las tablas pertenezcan al esquema 'Compementario'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Complementario'
GO

INSERT INTO Complementario.MonedaExtranjera(Nombre,PrecioAR)
VALUES ('USD',1110)
GO

INSERT INTO Complementario.MediosDePago(NombreING,NombreESP)
VALUES ('Credit card','Tarjeta de credito'),('Cash','Efectivo'),('Ewallet','Billetera Electronica')
GO

DROP SCHEMA IF EXISTS Ventas
GO
CREATE SCHEMA Ventas
GO

DROP TABLE IF EXISTS ##Historial
GO
CREATE TABLE ##Historial(
	Id CHAR(11) PRIMARY KEY,
	TipoFactura CHAR(1),
	Ciudad VARCHAR(15),
	TipoCliente CHAR(6),
	Genero VARCHAR(6),
	Producto NVARCHAR(100),
	PrecioUni DECIMAL(6,2),
	Cantidad INT,
	Fecha DATE,
	Hora TIME,
	MedioPago VARCHAR(11),
	Empleado INT,
	IdMedPago VARCHAR(30)
)

DROP TABLE IF EXISTS Ventas.Facturas
GO
CREATE TABLE Ventas.Facturas(
	Id CHAR(11) PRIMARY KEY,
	TipoFactura CHAR(1),
	Ciudad VARCHAR(15),
	TipoCliente CHAR(6),									--Member o Normal
	Genero VARCHAR(6),										--Male/Female/Other
	IdProducto INT,
	Cantidad INT,
	Fecha DATE,
	Hora TIME(0),
	IdMedioPago INT,
	Empleado INT,
	IdSucursal INT,
	CONSTRAINT FK_Producto FOREIGN KEY (IdProducto) REFERENCES Productos.Catalogo(Id),
	CONSTRAINT FK_MedioDePago FOREIGN KEY (IdMedioPago) REFERENCES Complementario.MediosDePago(IdMDP),
	CONSTRAINT FK_Legajo FOREIGN KEY (Empleado) REFERENCES Complementario.Empleados(Legajo),
	CONSTRAINT FK_Sucursal FOREIGN KEY (IdSucursal) REFERENCES Complementario.Sucursales(IdSucursal)
)

DROP TABLE IF EXISTS Ventas.NotasCredito
GO
CREATE TABLE Ventas.NotasCredito (
    Id INT IDENTITY(1,1) PRIMARY KEY,        -- ID de la nota de crédito
    IdFactura CHAR(11),                      -- ID de la factura asociada (clave foránea)
	EstaActivo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_NotaCredito_Factura FOREIGN KEY (IdFactura) REFERENCES Ventas.Facturas(Id),
)

--Para ver que las tablas pertenezcan al esquema 'Ventas'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Ventas'
<<<<<<< Updated upstream
GO
=======
GO

------Para hacer el DER
WITH fk_info AS (
    SELECT
        JSON_QUERY(
            '[' + STRING_AGG(
                CONVERT(nvarchar(max),
                JSON_QUERY(N'{"schema": "' + COALESCE(REPLACE(tp_schema.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            '", "table": "' + COALESCE(REPLACE(tp.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            '", "column": "' + COALESCE(REPLACE(cp.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            '", "foreign_key_name": "' + COALESCE(REPLACE(fk.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            '", "reference_schema": "' + COALESCE(REPLACE(tr_schema.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            '", "reference_table": "' + COALESCE(REPLACE(tr.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            '", "reference_column": "' + COALESCE(REPLACE(cr.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            '", "fk_def": "FOREIGN KEY (' + COALESCE(REPLACE(cp.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            ') REFERENCES ' + COALESCE(REPLACE(tr.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            '(' + COALESCE(REPLACE(cr.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                            ') ON DELETE ' + fk.delete_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS +
                            ' ON UPDATE ' + fk.update_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS + '"}')
                ), ','
            ) + N']'
        ) AS all_fks_json
    FROM sys.foreign_keys AS fk
    JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
    JOIN sys.tables AS tp ON fkc.parent_object_id = tp.object_id
    JOIN sys.schemas AS tp_schema ON tp.schema_id = tp_schema.schema_id
    JOIN sys.columns AS cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
    JOIN sys.tables AS tr ON fkc.referenced_object_id = tr.object_id
    JOIN sys.schemas AS tr_schema ON tr.schema_id = tr_schema.schema_id
    JOIN sys.columns AS cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
), pk_info AS (
    SELECT
        JSON_QUERY(
            '[' + STRING_AGG(
                CONVERT(nvarchar(max),
                JSON_QUERY(N'{"schema": "' + COALESCE(REPLACE(pk.TABLE_SCHEMA, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "table": "' + COALESCE(REPLACE(pk.TABLE_NAME, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "column": "' + COALESCE(REPLACE(pk.COLUMN_NAME, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "pk_def": "PRIMARY KEY (' + pk.COLUMN_NAME COLLATE SQL_Latin1_General_CP1_CI_AS + ')"}')
                ), ','
            ) + N']'
        ) AS all_pks_json
    FROM
        (
            SELECT
                kcu.TABLE_SCHEMA,
                kcu.TABLE_NAME,
                kcu.COLUMN_NAME
            FROM
                INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
            JOIN
                INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
                ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
                AND kcu.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
            WHERE
                tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
        ) pk
),
cols AS (
    SELECT
        JSON_QUERY(
            '[' + STRING_AGG(
                CONVERT(nvarchar(max),
                JSON_QUERY('{"schema": "' + COALESCE(REPLACE(cols.TABLE_SCHEMA, '"', ''), '') +
                '", "table": "' + COALESCE(REPLACE(cols.TABLE_NAME, '"', ''), '') +
                '", "name": "' + COALESCE(REPLACE(cols.COLUMN_NAME, '"', ''), '') +
                '", "ordinal_position": "' + CAST(cols.ORDINAL_POSITION AS NVARCHAR(MAX)) +
                '", "type": "' + LOWER(cols.DATA_TYPE) +
                '", "character_maximum_length": "' +
                    COALESCE(CAST(cols.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(MAX)), 'null') +
                '", "precision": ' +
                    CASE
                        WHEN cols.DATA_TYPE IN ('numeric', 'decimal') THEN
                            CONCAT('{"precision":', COALESCE(CAST(cols.NUMERIC_PRECISION AS NVARCHAR(MAX)), 'null'),
                            ',"scale":', COALESCE(CAST(cols.NUMERIC_SCALE AS NVARCHAR(MAX)), 'null'), '}')
                        ELSE
                            'null'
                    END +
                ', "nullable": "' +
                    CASE WHEN cols.IS_NULLABLE = 'YES' THEN 'true' ELSE 'false' END +
                '", "default": "' +
                    COALESCE(REPLACE(CAST(cols.COLUMN_DEFAULT AS NVARCHAR(MAX)), '"', '\"'), '') +
                '", "collation": "' +
                    COALESCE(cols.COLLATION_NAME, '') +
                '"}')
                ), ','
            ) + ']'
        ) AS all_columns_json
    FROM
        INFORMATION_SCHEMA.COLUMNS cols
    WHERE
        cols.TABLE_CATALOG = DB_NAME()
),
indexes AS (
    SELECT
        '[' + STRING_AGG(
            CONVERT(nvarchar(max),
            JSON_QUERY(
                N'{"schema": "' + COALESCE(REPLACE(s.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "table": "' + COALESCE(REPLACE(t.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "name": "' + COALESCE(REPLACE(i.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "column": "' + COALESCE(REPLACE(c.name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "index_type": "' + LOWER(i.type_desc) COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "unique": ' + CASE WHEN i.is_unique = 1 THEN 'true' ELSE 'false' END +
                ', "direction": "' + CASE WHEN ic.is_descending_key = 1 THEN 'desc' ELSE 'asc' END COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "column_position": ' + CAST(ic.key_ordinal AS nvarchar(max)) + N'}'
            )
            ), ','
        ) + N']' AS all_indexes_json
    FROM
        sys.indexes i
    JOIN
        sys.tables t ON i.object_id = t.object_id
    JOIN
        sys.schemas s ON t.schema_id = s.schema_id
    JOIN
        sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    JOIN
        sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE
        s.name LIKE '%'
        AND i.name IS NOT NULL
),
tbls AS (
    SELECT
        '[' + STRING_AGG(
            CONVERT(nvarchar(max),
            JSON_QUERY(
                N'{"schema": "' + COALESCE(REPLACE(aggregated.schema_name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "table": "' + COALESCE(REPLACE(aggregated.table_name, '"', ''), '') COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "row_count": "' + CAST(aggregated.row_count AS NVARCHAR(MAX)) +
                '", "table_type": "' + aggregated.table_type COLLATE SQL_Latin1_General_CP1_CI_AS +
                '", "creation_date": "' + CONVERT(NVARCHAR(MAX), aggregated.creation_date, 120) + '"}'
            )
            ), ','
        ) + N']' AS all_tables_json
    FROM
        (
            -- Select from tables
            SELECT
                COALESCE(REPLACE(s.name, '"', ''), '') AS schema_name,
                COALESCE(REPLACE(t.name, '"', ''), '') AS table_name,
                SUM(p.rows) AS row_count,
                t.type_desc AS table_type,
                t.create_date AS creation_date
            FROM
                sys.tables t
            JOIN
                sys.schemas s ON t.schema_id = s.schema_id
            JOIN
                sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
            WHERE
                s.name LIKE '%'
            GROUP BY
                s.name, t.name, t.type_desc, t.create_date

            UNION ALL

            -- Select from views
            SELECT
                COALESCE(REPLACE(s.name, '"', ''), '') AS table_name,
                COALESCE(REPLACE(v.name, '"', ''), '') AS object_name,
                0 AS row_count,  -- Views don't have row counts
                'VIEW' AS table_type,
                v.create_date AS creation_date
            FROM
                sys.views v
            JOIN
                sys.schemas s ON v.schema_id = s.schema_id
            WHERE
                s.name LIKE '%'
        ) AS aggregated
),
views AS (
    SELECT
        '[' + STRING_AGG(
            CONVERT(nvarchar(max),
            JSON_QUERY(
                N'{"schema": "' + STRING_ESCAPE(COALESCE(s.name, ''), 'json') +
                '", "view_name": "' + STRING_ESCAPE(COALESCE(v.name, ''), 'json') +
                '", "view_definition": "' +
                STRING_ESCAPE(
                    CAST(
                        '' AS XML
                    ).value(
                        'xs:base64Binary(sql:column("DefinitionBinary"))',
                        'VARCHAR(MAX)'
                    ), 'json') +
                '"}'
            )
            ), ','
        ) + N']' AS all_views_json
    FROM
        sys.views v
    JOIN
        sys.schemas s ON v.schema_id = s.schema_id
    JOIN
        sys.sql_modules m ON v.object_id = m.object_id
    CROSS APPLY
        (SELECT CONVERT(VARBINARY(MAX), m.definition) AS DefinitionBinary) AS bin
    WHERE
        s.name LIKE '%'
)
SELECT JSON_QUERY(
        N'{"fk_info": ' + ISNULL((SELECT cast(all_fks_json as nvarchar(max)) FROM fk_info), N'[]') +
        ', "pk_info": ' + ISNULL((SELECT cast(all_pks_json as nvarchar(max)) FROM pk_info), N'[]') +
        ', "columns": ' + ISNULL((SELECT cast(all_columns_json as nvarchar(max)) FROM cols), N'[]') +
        ', "indexes": ' + ISNULL((SELECT cast(all_indexes_json as nvarchar(max)) FROM indexes), N'[]') +
        ', "tables": ' + ISNULL((SELECT cast(all_tables_json as nvarchar(max)) FROM tbls), N'[]') +
        ', "views": ' + ISNULL((SELECT cast(all_views_json as nvarchar(max)) FROM views), N'[]') +
        ', "database_name": "' + DB_NAME() + '"' +
        ', "version": ""}'
) AS metadata_json_to_import; 
>>>>>>> Stashed changes
