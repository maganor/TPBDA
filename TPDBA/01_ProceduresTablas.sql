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
    @Sucursal VARCHAR(100),
    @Turno VARCHAR(25)
AS
BEGIN
    DECLARE @IdSucursal INT;

    SELECT @IdSucursal = IdSucursal
    FROM Complementario.Sucursales
    WHERE Ciudad = @Sucursal;

    IF @IdSucursal IS NULL
    BEGIN
        RAISERROR ('La sucursal especificada no existe o la ciudad no es válida.', 16, 1);
        RETURN;
    END
	   
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
    @IdSucursal INT = NULL,  
    @Turno VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Complementario.Empleados										
    SET 
        Cargo = COALESCE(@Cargo, Cargo),
        Sucursal = COALESCE(@IdSucursal, Sucursal),						
        Turno = COALESCE(@Turno, Turno),
        Direccion = COALESCE(@Direccion, Direccion),
        EmailPersonal = COALESCE(@EmailPersonal, EmailPersonal)
    WHERE Legajo = @Legajo;
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.AgregarOActualizarProducto
    @Nombre VARCHAR(100),
    @Precio DECIMAL(6,2),
    @IdCategoria INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (															-- Comprueba si ya existe el producto en el catálogo
        SELECT 1
        FROM Productos.Catalogo
        WHERE Nombre = @Nombre AND IdCategoria = @IdCategoria
    )
    BEGIN
        UPDATE Productos.Catalogo										-- Si existe, actualiza el precio
        SET Precio = @Precio
        WHERE Nombre = @Nombre AND IdCategoria = @IdCategoria;
    END
    ELSE
    BEGIN
        INSERT INTO Productos.Catalogo (Nombre, Precio, IdCategoria)	-- Si no existe, insertar el nuevo producto
        VALUES (@Nombre, @Precio, @IdCategoria);
    END
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
        RAISERROR ('El Medio de Pago ya existe.', 16, 1);
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
    IF EXISTS (														-- Comprueba si ya existe una sucursal en la misma ciudad y dirección
        SELECT 1
        FROM Complementario.Sucursales
        WHERE Ciudad = @Ciudad AND Direccion = @Direccion AND ReemplazarPor = @ReemplazarPor
    )
    BEGIN
        RAISERROR ('Ya existe esa sucursal', 16, 1);
        RETURN;
    END
    INSERT INTO Complementario.Sucursales (Ciudad, ReemplazarPor, Direccion, Horario, Telefono)	-- Inserta la nueva sucursal si no existe
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
    @IdFactura CHAR(11)													
AS
BEGIN
    DECLARE @IdProducto INT;

    SELECT @IdProducto = IdProducto										-- Obtiene el IdProducto asociado con la factura
    FROM Ventas.Facturas
    WHERE Id = @IdFactura;

    IF @IdProducto IS NOT NULL
    BEGIN
        INSERT INTO Ventas.NotasCredito (IdFactura, EstaActivo)			-- Crea la nota de crédito, asociándola con la factura y el producto
        VALUES (@IdFactura, 1);  
    END
    ELSE
    BEGIN
        RAISERROR('No se encontró un producto asociado con la factura proporcionada.', 16, 1);
    END
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarNotaCredito
    @Id INT
AS
BEGIN
    UPDATE Ventas.NotasCredito
    SET EstaActivo = 0
    WHERE Id = @Id;
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.AgregarCliente
    @Nombre VARCHAR(50),
    @TipoCliente CHAR(6),
    @Genero CHAR(6),
	@DNI INT
AS
BEGIN
        IF EXISTS (SELECT 1 FROM Complementario.Clientes WHERE DNI = @DNI) -- Inserta el cliente en la tabla solo si no está su dni ya ingresado
        BEGIN
            RAISERROR('Ya esiste un cliente con el DNI ingresado.', 16, 1);
            RETURN;
        END

        INSERT INTO Complementario.Clientes (Nombre, TipoCliente, Genero, DNI)
        VALUES (@Nombre, @TipoCliente, @Genero, @DNI);
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.ModificarCliente
	@DNI INT,
	@TipoClienteNuevo CHAR(6)
AS
BEGIN
      IF NOT EXISTS (SELECT 1 FROM Complementario.Clientes WHERE DNI = @DNI)
      BEGIN
           RAISERROR('No existe un cliente con el DNI ingresado.', 16, 1);
		   RETURN;
      END
      
	  UPDATE Complementario.Clientes
      SET TipoCliente = @TipoClienteNuevo
      WHERE DNI = @DNI;
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarCliente
    @IdCliente INT
AS
BEGIN
       IF NOT EXISTS (SELECT 1 FROM Complementario.Clientes WHERE IdCliente = @IdCliente)
       BEGIN
            RAISERROR('No existe un cliente con el ID ingresado.', 16, 1);
            RETURN;
       END

       DELETE FROM Complementario.Clientes
       WHERE IdCliente = @IdCliente;   
END;
GO


-----Despues pasar a testing
EXEC Procedimientos.ModificarCliente
    @DNI = 43525943,
    @TipoClienteNuevo = 'NORMAL';

EXEC Procedimientos.ModificarCliente
    @DNI = 44925943,
    @TipoClienteNuevo = 'VIP';

	
USE Com5600G01
GO
EXEC Procedimientos.CargarCliente
    @Nombre = 'Juan Fer Perez',
    @TipoCliente = 'VIP',
    @Genero = 'M',
	@DNI = 43525943;

EXEC Procedimientos.EliminarCliente
    @IdCliente = 1;
