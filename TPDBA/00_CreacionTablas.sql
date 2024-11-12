
--Trabajo Practico Integrador - Bases de Datos Aplicada:
--Integrantes:
--Antola Ortiz, Mauricio Gabriel  -       44613237 
--Tempra, Francisco               -       44485891
--Villegas Brandolini, Lucas      -       44459666
--Zapata, Santiago                -       44525943

---CREACION DE OBJETOS:

USE master
GO

CREATE DATABASE Com5600G01
GO

USE Com5600G01
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

DROP TABLE IF EXISTS Complementario.Sucursales
GO
CREATE TABLE Complementario.Sucursales(
		IdSucursal INT IDENTITY(1,1) PRIMARY KEY,
        Ciudad VARCHAR(100),				--Ciudad
        ReemplazarPor VARCHAR(100),			--Sucursal donde trabaja
        Direccion VARCHAR(200),
        Horario VARCHAR(100),
        Telefono VARCHAR(20)
)
GO

DROP TABLE IF EXISTS Complementario.Empleados
GO
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
    IdSucursal INT,
    Turno VARCHAR(25),
	EstaActivo BIT NOT NULL DEFAULT 1,
	CONSTRAINT FK_Sucursal FOREIGN KEY (IdSucursal) REFERENCES Complementario.Sucursales(IdSucursal)
)
GO

DROP TABLE IF EXISTS Complementario.CategoriaDeProds
CREATE TABLE Complementario.CategoriaDeProds(
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

DROP TABLE IF EXISTS Complementario.Clientes
GO
CREATE TABLE Complementario.Clientes(
    IdCliente INT IDENTITY(0,1) PRIMARY KEY,  
    DNI INT UNIQUE,
    Nombre VARCHAR(50),
    TipoCliente CHAR(6),
    Genero CHAR(6)
)
GO

INSERT INTO Complementario.Clientes (DNI, Nombre, TipoCliente, Genero)  
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
	CONSTRAINT FK_Categoria FOREIGN KEY (IdCategoria) REFERENCES Complementario.CategoriaDeProds(Id)
)

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
	CONSTRAINT FK_Legajo FOREIGN KEY (Empleado) REFERENCES Complementario.Empleados(Legajo),
	CONSTRAINT FK_Sucursal FOREIGN KEY (IdSucursal) REFERENCES Complementario.Sucursales(IdSucursal),
	CONSTRAINT FK_Cliente FOREIGN KEY (IdCliente) REFERENCES Complementario.Clientes(IdCliente)
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
    PrecioUnitario DECIMAL(6, 2),										
    CONSTRAINT FK_Detalle_Factura FOREIGN KEY (IdFactura) REFERENCES Ventas.Facturas(IdFactura),
    CONSTRAINT FK_Detalle_Producto FOREIGN KEY (IdProducto) REFERENCES Productos.Catalogo(Id),
	CONSTRAINT FK_Detalle_Categoria FOREIGN KEY (IdCategoria) REFERENCES Complementario.CategoriaDeProds(Id)
)
GO

CREATE TABLE Ventas.NotasDeCredito (
    Id INT IDENTITY(1,1) PRIMARY KEY,       
    IdProd INT,                            
    IdFactura INT,                    
    EstadoActivo BIT,                   
    Cantidad INT,                       
    IdCategoria INT,                   
    Precio DECIMAL(6, 2),                 
    CONSTRAINT FK_Nota_Factura FOREIGN KEY (IdFactura) REFERENCES Ventas.Facturas(IdFactura),
    CONSTRAINT FK_Nota_Producto FOREIGN KEY (IdProd) REFERENCES Productos.Catalogo(Id),
    CONSTRAINT FK_Nota_Categoria FOREIGN KEY (IdCategoria) REFERENCES Complementario.CategoriaDeProds(Id)
);


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

--Creacion de Indices para las futuras ejecuciones de los SP:
CREATE NONCLUSTERED INDEX IX_CategoriaDeProds_Producto_Linea ON Complementario.CategoriaDeProds(Producto,LineadeProducto);
CREATE NONCLUSTERED INDEX IX_Catalogo_Nombre_Categoria ON Productos.Catalogo(Nombre,IdCategoria);
CREATE NONCLUSTERED INDEX IX_SucursalesCiudad ON Complementario.Sucursales(Ciudad,ReemplazarPor);
