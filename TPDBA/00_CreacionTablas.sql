
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
	EstaActivo BIT NOT NULL DEFAULT 1
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
    IdProducto INT,                          -- ID del producto devuelto (clave foránea)
	EstaActivo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_NotaCredito_Factura FOREIGN KEY (IdFactura) REFERENCES Ventas.Facturas(Id),
    CONSTRAINT FK_NotaCredito_Producto FOREIGN KEY (IdProducto) REFERENCES Productos.Catalogo(Id)
)

--Para ver que las tablas pertenezcan al esquema 'Ventas'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Ventas'
GO