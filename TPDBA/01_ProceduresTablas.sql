USE Com5600G01
GO 

DROP SCHEMA IF EXISTS Procedimientos
GO
CREATE SCHEMA Procedimientos 
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
    @Sucursal VARCHAR(100), -- Recibe el nombre de la ciudad
    @Turno VARCHAR(25)
AS
BEGIN
    DECLARE @IdSucursal INT;

    -- Obtener el IdSucursal correspondiente al nombre de la ciudad
    SELECT @IdSucursal = IdSucursal
    FROM Complementario.Sucursales
    WHERE Ciudad = @Sucursal;

    -- Si no se encontró la sucursal o no existe la ciudad, lanzar un error
    IF @IdSucursal IS NULL
    BEGIN
        RAISERROR ('La sucursal especificada no existe o la ciudad no es válida.', 16, 1);
        RETURN;
    END
	    -- Insertar el nuevo empleado
    INSERT INTO Complementario.Empleados 
        (Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo, IdSucursal, Turno, EstaActivo)
    VALUES 
        (@Nombre, @Apellido, @DNI, @Direccion, @EmailPersonal, @EmailEmpresa, @CUIL, @Cargo, @IdSucursal, @Turno, 1);
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
    @IdSucursal INT = NULL,  -- Recibe el IdSucursal directamente
    @Turno VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Actualizar los datos del empleado
    UPDATE Complementario.Empleados
    SET 
        Cargo = COALESCE(@Cargo, Cargo),
        Sucursal = COALESCE(@IdSucursal, Sucursal),  -- Se actualiza con el IdSucursal directamente
        Turno = COALESCE(@Turno, Turno),
        Direccion = COALESCE(@Direccion, Direccion),
        EmailPersonal = COALESCE(@EmailPersonal, EmailPersonal)
    WHERE Legajo = @Legajo;
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarProductoCatalogo
    @Id INT
AS
BEGIN
    DELETE FROM Productos.Catalogo
    WHERE Id = @Id
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.AgregarMedioDePago
    @nombreING VARCHAR(15),
    @nombreESP VARCHAR(25)
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Complementario.MediosDePago
        WHERE NombreING = @nombreING AND NombreESP = @nombreESP
    )
    BEGIN
        RAISERROR ('El medio de pago con estos valores ya existe.', 16, 1);
        RETURN;
    END
   
    INSERT INTO Complementario.MediosDePago (NombreING, NombreESP)
    VALUES (@nombreING, @nombreESP);
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
    -- Comprobar si ya existe una sucursal en la misma ciudad y dirección
    IF EXISTS (
        SELECT 1
        FROM Complementario.Sucursales
        WHERE Ciudad = @Ciudad AND Direccion = @Direccion AND ReemplazarPor = @ReemplazarPor
    )
    BEGIN
        RAISERROR ('Ya existe esa sucursal', 16, 1);
        RETURN;
    END
    -- Inserta la nueva sucursal si no existe
    INSERT INTO Complementario.Sucursales (Ciudad, ReemplazarPor, Direccion, Horario, Telefono)
    VALUES (@Ciudad, @ReemplazarPor, @Direccion, @Horario, @Telefono);
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