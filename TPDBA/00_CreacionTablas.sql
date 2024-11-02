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

DROP TABLE IF EXISTS ##Catalogo
GO
CREATE TABLE ##Catalogo(
	Id int primary key,
	Categoria varchar(100),
	Nombre nvarchar(100),
	Precio decimal(6,2),
	Precio_Ref decimal(6,2),
	Unidad_Ref varchar(10),
	Fecha datetime
)

DROP TABLE IF EXISTS ##ProductosImportados
GO
CREATE TABLE ##ProductosImportados(
	IdProducto INT PRIMARY KEY,
    NombreProducto NVARCHAR(100),
    Proveedor VARCHAR(100),
    Categoria VARCHAR(50),
    CantidadPorUnidad VARCHAR(50),
    PrecioUnidad DECIMAL(6,2),
)

DROP TABLE IF EXISTS ##ElectronicAccessories
CREATE TABLE ##ElectronicAccessories(
   Producto NVARCHAR(100),
   PrecioUSD DECIMAL(6,2)
)

DROP TABLE IF EXISTS Productos.CatalogoFinal
GO
CREATE TABLE Productos.CatalogoFinal(
	Id int IDENTITY (1,1) primary key,
	LineaDeProducto varchar(100),
	Nombre nvarchar(100),
	Precio decimal(6,2),
	Proveedor varchar(100)
)

--Para ver que las tablas pertenezcan al esquema 'Productos'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Productos'
GO

DROP SCHEMA IF EXISTS Ventas
GO
CREATE SCHEMA Ventas
GO

DROP TABLE IF EXISTS ##Historial
GO
CREATE TABLE ##Historial(
	Id char(11) primary key,
	Tipo_Factura char(1),
	Ciudad varchar(15),
	Tipo_Cliente char(6),
	Genero varchar(6),
	Producto nvarchar(100),
	PrecioUni decimal(6,2),
	Cantidad int,
	Fecha date,
	Hora time,
	MedioPago varchar(11),
	Empleado int,
	IdMedPago varchar(30)
)

DROP TABLE IF EXISTS Ventas.VtasAReg
GO
CREATE TABLE Ventas.VtasAReg(
	Id char(11) primary key,
	Tipo_Factura char(1),
	Ciudad varchar(15),
	Tipo_Cliente char(6),
	Genero varchar(6),
	LineaDeProducto varchar(100),
	Producto nvarchar(100),
	PrecioUni decimal(6,2),
	Cantidad int,
	Fecha date,
	Hora time(0),
	MedioPago varchar(11),
	Empleado int,
	Sucursal varchar(17)
)

--Para ver que las tablas pertenezcan al esquema 'Ventas'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Ventas'
GO

--if exists .... schema*
--Se crea este esquema para la info complementaria.
DROP SCHEMA IF EXISTS Complementario
GO
CREATE SCHEMA Complementario
GO

DROP TABLE IF EXISTS Complementario.Empleados
CREATE TABLE Complementario.Empleados (
    Legajo INT NOT NULL,
    Nombre VARCHAR(50),
    Apellido VARCHAR(50),
    DNI INT,
    Direccion VARCHAR(200),
    emailPersonal VARCHAR(100),
    emailEmpresa VARCHAR(100),
    CUIL VARCHAR(11),
    Cargo VARCHAR(50),
    Sucursal VARCHAR(100),
    Turno VARCHAR(25)
);
GO

DROP TABLE IF EXISTS Complementario.Sucursales
CREATE TABLE Complementario.Sucursales (
        Ciudad VARCHAR(100),
        ReemplazarPor VARCHAR(100),
        direccion VARCHAR(200),
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
	Id int identity(1,1) primary key,
	Nombre char(3),
	PrecioAR decimal(6,2)
)
GO

--Para ver que las tablas pertenezcan al esquema 'Compementario'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Complementario'
GO

INSERT INTO Complementario.MonedaExtranjera(Nombre,PrecioAR)
VALUES ('USD',1225)
GO