USE Com5600G01
GO 

DROP SCHEMA IF EXISTS Procedimientos
GO
CREATE SCHEMA Procedimientos 
GO

CREATE OR ALTER PROCEDURE Procedimientos.AgregarFactura
    @cantidad INT,
    @tipoCliente CHAR(6),
    @genero CHAR(6),
    @empleado INT,
    @tipoFactura CHAR,
    @medioDePago CHAR(11),
    @producto VARCHAR(100),
    @ciudad VARCHAR(15),
    @id CHAR(11)
AS
BEGIN
    DECLARE @IdProducto INT
    DECLARE @IdSucursal INT
    DECLARE @IdMedioPago INT
    DECLARE @precio DECIMAL(6,2)

    -- Obtener IdProducto y precio
    SELECT @IdProducto = Id, @precio = Precio 
    FROM Productos.Catalogo 
    WHERE Nombre = @producto;

    -- Validar que se haya encontrado el producto
    IF @IdProducto IS NULL
    BEGIN
        RAISERROR('Producto NO encontrado', 16, 1);
        RETURN;
    END
    -- Obtener IdSucursal según la ciudad
    SELECT @IdSucursal = IdSucursal 
    FROM Complementario.Sucursales 
    WHERE Ciudad = @ciudad;

    -- Validar que se haya encontrado la sucursal
    IF @IdSucursal IS NULL
    BEGIN
        RAISERROR('Sucursal NO encontrada', 16, 1);
        RETURN;
    END
    -- Obtener IdMedioPago según el nombre en inglés del medio de pago
    SELECT @IdMedioPago = IdMDP 
    FROM Complementario.MediosDePago 
    WHERE NombreING = @medioDePago OR NombreESP = @medioDePago;
    -- Validar que se haya encontrado el medio de pago
    IF @IdMedioPago IS NULL
    BEGIN
        RAISERROR('Medio de Pago NO encontrado', 16, 1);
        RETURN;
    END
    -- Validar que el empleado exista
    IF NOT EXISTS (SELECT 1 FROM Complementario.Empleados WHERE Legajo = @empleado)
    BEGIN
        RAISERROR('Empleado NO encontrado', 16, 1);
        RETURN;
    END
    -- Insertar en la tabla Ventas.Facturas
    INSERT INTO Ventas.Facturas (Id,TipoFactura,Ciudad,TipoCliente,Genero,IdProducto,Cantidad,Fecha,Hora,IdMedioPago,Empleado,IdSucursal)
    VALUES (
        @id, @tipoFactura, @ciudad, @tipoCliente, @genero, 
        @IdProducto, @cantidad, GETDATE(), CAST(SYSDATETIME() AS TIME(0)), 
        @IdMedioPago, @empleado, @IdSucursal
    );
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.MostrarFacturas
AS
BEGIN
    SELECT 
        f.Id AS [ID Factura],
        f.TipoFactura AS [Tipo de Factura],
        f.Ciudad AS [Ciudad],
        f.TipoCliente AS [Tipo de Cliente],
        f.Genero AS [Género],
        c.LineaDeProducto AS [Línea de Producto],
        c.Nombre AS [Producto],
        FORMAT(c.Precio * me.PrecioAR, 'N2') AS [Precio Unitario], -- Convertimos el precio a pesos, multiplicando el precio en USD por el precio AR de la moneda extranjera
        f.Cantidad AS [Cantidad],
        f.Fecha AS [Fecha],
        f.Hora AS [Hora],
        mdp.NombreESP AS [Medio de Pago],
        f.Empleado AS [Empleado],
        s.ReemplazarPor AS [Sucursal]
    FROM Ventas.Facturas AS f
    JOIN Productos.Catalogo AS c ON f.IdProducto = c.Id
    JOIN Complementario.MonedaExtranjera AS me ON me.Nombre = 'USD' 
    JOIN Complementario.MediosDePago AS mdp ON f.IdMedioPago = mdp.IdMDP
    JOIN Complementario.Sucursales AS s ON f.IdSucursal = s.IdSucursal
	ORDER BY f.fecha, f.hora
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.AgregarEmpleado
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @DNI INT,
    @Direccion VARCHAR(200),
    @EmailPersonal VARCHAR(100),
    @EmailEmpresa VARCHAR(100),
    @CUIL VARCHAR(11),
    @Cargo VARCHAR(50),
    @Sucursal VARCHAR(100),
    @Turno VARCHAR(25),
	@FraseClave NVARCHAR(128)
AS
BEGIN
	DECLARE @Legajo INT
	SELECT @Legajo = MAX(E.Legajo) FROM Complementario.Empleados as E
    INSERT INTO Complementario.Empleados(Legajo,Nombre,Apellido,DNI,Direccion,EmailPersonal,EmailEmpresa,CUIL,Cargo,Sucursal,Turno, EstaActivo)
    VALUES (
		@Legajo + 1,
        @Nombre,
        @Apellido,
        @DNI,
        @Direccion,
        @EmailPersonal,
        @EmailEmpresa,
        @CUIL,
        @Cargo,
        @Sucursal,
        @Turno,
		1,
		EncryptByPassPhrase(@FraseClave, CONVERT(NVARCHAR(12), @DNI)),				-- Cifrado del DNI
        EncryptByPassPhrase(@FraseClave, @Direccion),								-- Cifrado de la dirección
        EncryptByPassPhrase(@FraseClave, @EmailPersonal),							-- Cifrado del email personal
        EncryptByPassPhrase(@FraseClave, @CUIL)										-- Cifrado del CUIL
    );
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarEmpleado
	@Legajo INT
AS 
BEGIN
	UPDATE Complementario.Empleados
	SET EstaActivo = 0
	WHERE Legajo = @Legajo
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.ActualizarEmpleado
    @Legajo INT,
    @Direccion VARCHAR(200) = NULL,
    @EmailPersonal VARCHAR(100) = NULL,
    @Cargo VARCHAR(50) = NULL,
    @Sucursal VARCHAR(100) = NULL,
    @Turno VARCHAR(25) = NULL,
	@FraseClave NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Complementario.Empleados
    SET 
        Cargo = COALESCE(@Cargo, Cargo),
        Sucursal = COALESCE(@Sucursal, Sucursal),
        Turno = COALESCE(@Turno, Turno),
        -- Cifrado de los campos sensibles solo si el nuevo valor es proporcionado
        Direccion_Cifrada = CASE 
                              WHEN @Direccion IS NOT NULL THEN EncryptByPassPhrase(@FraseClave, @Direccion) 
                              ELSE Direccion_Cifrada 
							END,
        EmailPersonal_Cifrado = CASE 
                                  WHEN @EmailPersonal IS NOT NULL THEN EncryptByPassPhrase(@FraseClave, @EmailPersonal) 
                                  ELSE EmailPersonal_Cifrado 
								END,
   WHERE Legajo = @Legajo;
END
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarProductoCatalogo
    @nombreProd varchar(100)
AS
BEGIN
    DELETE FROM Productos.Catalogo
    WHERE Nombre = @nombreProd
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.AgregarMedioDePago
	@nombreING varchar(15),
	@nombreESP varchar(25)
AS
BEGIN
	INSERT INTO Complementario.MediosDePago(NombreING,NombreESP)
	VALUES(@nombreING,@nombreESP)
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarMedioDePago
	@id INT
AS
BEGIN
	DELETE FROM Complementario.MediosDePago
	WHERE IdMDP = @id
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.AgregarSucursal
	@Ciudad VARCHAR(100),
    @ReemplazarPor VARCHAR(100),
    @Direccion VARCHAR(200),
    @Horario VARCHAR(100),
    @Telefono VARCHAR(20)
AS
BEGIN
	INSERT INTO Complementario.Sucursales(Ciudad,ReemplazarPor,Direccion,Horario,Telefono)
	VALUES(@Ciudad,@ReemplazarPor,@Direccion,@Horario,@Telefono)
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarSucursal
	@id int
AS
BEGIN
	DELETE FROM Complementario.Sucursales
	WHERE IdSucursal = @id
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.GenerarNotaCredito
    @IdFactura CHAR(11)    -- Parámetro que recibe el ID de la factura
AS
BEGIN
    DECLARE @IdProducto INT;

    -- Obtener el IdProducto asociado con la factura, por ejemplo, desde la tabla Ventas.Facturas
    SELECT @IdProducto = IdProducto  
    FROM Ventas.Facturas
    WHERE Id = @IdFactura;

    -- Verificar si se obtuvo un IdProducto
    IF @IdProducto IS NOT NULL
    BEGIN
        -- Crear la nota de crédito, asociándola con la factura y el producto
        INSERT INTO Ventas.NotasCredito (IdFactura, EstaActivo)
        VALUES (@IdFactura, 1);  -- 1 representa el estado activo
    END
    ELSE
    BEGIN
        -- Si no se encuentra un producto asociado a la factura, lanzar un error
        RAISERROR('No se encontró un producto asociado con la factura proporcionada.', 16, 1);
    END
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarNotaCredito
    @Id INT -- ID de la nota de crédito a actualizar
AS
BEGIN
    -- Actualizar el estado de la nota de crédito a inactivo (0)
    UPDATE Ventas.NotasCredito
    SET EstaActivo = 0
    WHERE Id = @Id;
END;
GO