
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

--Entrega 3:
--Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deberá entregar un archivo .sql con el script 
--completo de creación (debe funcionar si se lo ejecuta “tal cual” es entregado). Incluya comentarios para indicar qué hace cada
--módulo de código.

--Entrega 5:
--Cuando un cliente reclama la devolución de un producto se genera una nota de crédito por el valor del producto o un producto 
--del mismo tipo. Tener en cuenta que la nota de crédito debe estar asociada a una Factura con estado pagada

---CREACION DE LOS OBJETOS DE LA BASE DE DATOS:

USE master
GO

CREATE DATABASE Com5600G01
GO

USE Com5600G01
GO

--Creacion de los esquemas para cada tabla:

DROP SCHEMA IF EXISTS Sucursal
GO
CREATE SCHEMA Sucursal
GO
DROP SCHEMA IF EXISTS Productos
GO
CREATE SCHEMA Productos
GO
DROP SCHEMA IF EXISTS Complementario
GO
CREATE SCHEMA Complementario
GO
DROP SCHEMA IF EXISTS Ventas
GO
CREATE SCHEMA Ventas
GO
DROP SCHEMA IF EXISTS NotaCredito
GO
CREATE SCHEMA NotaCredito
GO

--Creacion de las tablas:

DROP TABLE IF EXISTS Sucursal.Sucursales
GO
CREATE TABLE Sucursal.Sucursales(
		IdSucursal INT IDENTITY(1,1) PRIMARY KEY,
        Ciudad VARCHAR(100),							--Ciudad
        ReemplazarPor VARCHAR(100),						--Sucursal donde trabaja
        Direccion VARCHAR(200),
        Horario VARCHAR(100),
        Telefono VARCHAR(20)
)
GO

DROP TABLE IF EXISTS Sucursal.Empleados
GO
CREATE TABLE Sucursal.Empleados(
    Legajo INT PRIMARY KEY,
    Nombre VARCHAR(50),
    Apellido VARCHAR(50),
    DNI INT,
    Direccion VARCHAR(200),
    EmailPersonal VARCHAR(100),
    EmailEmpresa VARCHAR(100),
    CUIL VARCHAR(14),
    Cargo VARCHAR(50),
    IdSucursal INT,
    Turno VARCHAR(25),
	EstaActivo BIT NOT NULL DEFAULT 1,
	CONSTRAINT FK_Sucursal FOREIGN KEY (IdSucursal) REFERENCES Sucursal.Sucursales(IdSucursal)
)
GO

DROP TABLE IF EXISTS Productos.CategoriaDeProds
GO
CREATE TABLE Productos.CategoriaDeProds(
	Id INT IDENTITY(1,1) PRIMARY KEY,
    LineaDeProducto VARCHAR(100),
    Producto VARCHAR(100)
)
GO

DROP TABLE IF EXISTS Complementario.ValorDolar
GO
CREATE TABLE Complementario.ValorDolar(
	Id INT IDENTITY(1,1) PRIMARY KEY,
	PrecioAR DECIMAL(6,2),
	FechaHora DATETIME2 DEFAULT SYSDATETIME(),
)
GO

DROP TABLE IF EXISTS Complementario.MediosDePago
GO
CREATE TABLE Complementario.MediosDePago(
	IdMDP INT IDENTITY(1,1) PRIMARY KEY,
	NombreING VARCHAR(15),
	NombreESP VARCHAR(25)
)
GO

DROP TABLE IF EXISTS Ventas.Clientes
GO
CREATE TABLE Ventas.Clientes(
    IdCliente INT IDENTITY(0,1) PRIMARY KEY,  
    DNI INT UNIQUE,
    Nombre VARCHAR(50),
    TipoCliente CHAR(6),
    Genero CHAR(6)
)
GO

-- Valores inciales para clientes que serán utiles para los proximos SP:

INSERT INTO Ventas.Clientes (DNI, Nombre, TipoCliente, Genero)  
VALUES (NULL, 'Consumidor Final', 'Normal', '-'), 
(0, 'Antiguo', 'Normal', 'Male'), (1, 'Antiguo', 'Normal', 'Female'), 
(2, 'Antiguo', 'Member', 'Female'), (3, 'Antiguo', 'Member', 'Male')
GO

DROP TABLE IF EXISTS Productos.Catalogo
GO
CREATE TABLE Productos.Catalogo(
	Id INT IDENTITY (1,1) PRIMARY KEY,
	Nombre VARCHAR(100),
	Precio DECIMAL(10,2),
	Proveedor VARCHAR(100),
	IdCategoria INT,
	PrecioRef DECIMAL(10,2),
	UnidadRef CHAR(10),
	Moneda CHAR(3) DEFAULT 'USD',
	CONSTRAINT FK_Categoria FOREIGN KEY (IdCategoria) REFERENCES Productos.CategoriaDeProds(Id)
)
GO

DROP TABLE IF EXISTS Ventas.Facturas
GO
CREATE TABLE Ventas.Facturas(
	IdFactura INT IDENTITY(1,1) PRIMARY KEY,
	IdViejo CHAR(11) DEFAULT '-',
	TipoFactura CHAR(1),					
	Fecha DATE,
	Hora TIME(0),
	IdMedioPago INT,
	Empleado INT,
	IdSucursal INT,
	IdCliente INT,
	CONSTRAINT FK_MedioDePago FOREIGN KEY (IdMedioPago) REFERENCES Complementario.MediosDePago(IdMDP),
	CONSTRAINT FK_Legajo FOREIGN KEY (Empleado) REFERENCES Sucursal.Empleados(Legajo),
	CONSTRAINT FK_Sucursal FOREIGN KEY (IdSucursal) REFERENCES Sucursal.Sucursales(IdSucursal),
	CONSTRAINT FK_Cliente FOREIGN KEY (IdCliente) REFERENCES Ventas.Clientes(IdCliente)
)
GO

DROP TABLE IF EXISTS Ventas.DetalleVentas
GO
CREATE TABLE Ventas.DetalleVentas(
	IdDetalle INT IDENTITY(1,1)PRIMARY KEY,         
    IdFactura INT,                              
    IdProducto INT,										
    IdCategoria INT,
    Cantidad INT,                                   
    PrecioUnitario DECIMAL(10, 2),
	Moneda CHAR(3),
    CONSTRAINT FK_Detalle_Factura FOREIGN KEY (IdFactura) REFERENCES Ventas.Facturas(IdFactura),
    CONSTRAINT FK_Detalle_Producto FOREIGN KEY (IdProducto) REFERENCES Productos.Catalogo(Id),
	CONSTRAINT FK_Detalle_Categoria FOREIGN KEY (IdCategoria) REFERENCES Productos.CategoriaDeProds(Id)
)
GO

DROP TABLE IF EXISTS NotaCredito.NotasDeCredito
GO
CREATE TABLE NotaCredito.NotasDeCredito(
    Id INT IDENTITY(1,1) PRIMARY KEY,       
    IdProd INT,                            
    IdFactura INT,                    
    EstadoActivo BIT,                   
    Cantidad INT,                       
    IdCategoria INT,                   
    Precio DECIMAL(6, 2),                 
    CONSTRAINT FK_Nota_Factura FOREIGN KEY (IdFactura) REFERENCES Ventas.Facturas(IdFactura),
    CONSTRAINT FK_Nota_Producto FOREIGN KEY (IdProd) REFERENCES Productos.Catalogo(Id),
    CONSTRAINT FK_Nota_Categoria FOREIGN KEY (IdCategoria) REFERENCES Productos.CategoriaDeProds(Id)
)
GO

--Para ver que las tablas pertenezcan al esquema 'Sucursal'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Sucursal'
GO

--Para ver que las tablas pertenezcan al esquema 'Productos'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Productos'
GO

--Para ver que las tablas pertenezcan al esquema 'Compementario'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Complementario'
GO

--Para ver que las tablas pertenezcan al esquema 'Ventas'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Ventas'
GO

--Para ver que las tablas pertenezcan al esquema 'NotaCredito'
SELECT TABLE_SCHEMA as Esquema, TABLE_NAME as Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'NotaCredito'
GO

--Vista para mostrar la factura como se pide:
CREATE OR ALTER VIEW Ventas.MostrarReporte
AS
	SELECT F.IdFactura,F.TipoFactura,S.Ciudad,C.TipoCliente,C.Genero,CP.LineaDeProducto,P.Nombre AS Producto,DV.PrecioUnitario,
		   DV.Cantidad,F.Fecha,F.Hora,MP.NombreESP AS MedioDePago,F.Empleado,S.ReemplazarPor AS Sucursal              
    
	FROM Ventas.Facturas F
		JOIN Sucursal.Sucursales S ON F.IdSucursal = S.IdSucursal         
		JOIN Ventas.Clientes C ON F.IdCliente = C.IdCliente         
		JOIN Ventas.DetalleVentas DV ON F.IdFactura = DV.IdFactura       
		JOIN Productos.CategoriaDeProds CP ON DV.IdCategoria = CP.Id   
		JOIN Productos.Catalogo P ON DV.IdProducto = P.Id      
		JOIN Complementario.MediosDePago MP ON F.IdMedioPago = MP.IdMDP
	WHERE DV.Cantidad > 0
GO

--Creacion de Indices para las futuras ejecuciones de los SP:
CREATE NONCLUSTERED INDEX IX_CategoriaDeProds_Producto_Linea ON Productos.CategoriaDeProds(Producto,LineadeProducto);
CREATE NONCLUSTERED INDEX IX_Catalogo_Nombre_Categoria ON Productos.Catalogo(Nombre,IdCategoria);
CREATE NONCLUSTERED INDEX IX_SucursalesCiudad ON Sucursal.Sucursales(Ciudad,ReemplazarPor);
