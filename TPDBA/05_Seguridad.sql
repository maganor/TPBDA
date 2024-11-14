USE Com5600G01	
go
CREATE OR ALTER PROCEDURE Procedimientos.PrepararTablaParaCifrar
AS
BEGIN
	ALTER TABLE Complementario.Empleados ADD DNICifrado VARBINARY(256)
	ALTER TABLE Complementario.Empleados ADD DireccionCifrada VARBINARY(256)
	ALTER TABLE Complementario.Empleados ADD EmailPersonalCifrado VARBINARY(256)
	ALTER TABLE Complementario.Empleados ADD CUILCifrado VARBINARY(256)
END
GO 

EXEC Procedimientos.PrepararTablaParaCifrar
GO

CREATE OR ALTER PROCEDURE Procedimientos.TransferirEmpleadosCifrados
	@FraseClave NVARCHAR(128)
AS
BEGIN
	--Se hace el pasaje de la tabla sin cifrar a la que esta cifrada (solo algunos campos "sensibles")
    UPDATE Complementario.Empleados
    SET 
        DNICifrado = EncryptByPassPhrase(@FraseClave, CAST(DNI AS VARCHAR(12)), 1, NULL),
        DireccionCifrada = EncryptByPassPhrase(@FraseClave, Direccion, 1, NULL),
        EmailPersonalCifrado = EncryptByPassPhrase(@FraseClave, EmailPersonal, 1, NULL),
        CUILCifrado = EncryptByPassPhrase(@FraseClave, CUIL, 1, NULL)

	 ALTER TABLE Complementario.Empleados DROP COLUMN DNI
     ALTER TABLE Complementario.Empleados DROP COLUMN Direccion
     ALTER TABLE Complementario.Empleados DROP COLUMN EmailPersonal
     ALTER TABLE Complementario.Empleados DROP COLUMN CUIL

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
    @FraseClave NVARCHAR(128)  -- Frase clave para cifrar los datos
AS
BEGIN
    DECLARE @IdSucursal INT;

    -- Obtener el IdSucursal para la sucursal especificada
    SELECT @IdSucursal = IdSucursal
    FROM Complementario.Sucursales
    WHERE ReemplazarPor = @Sucursal;

	DECLARE @Legajo INT
    SELECT @Legajo = MAX(Legajo) + 1
    FROM Complementario.Empleados;

    -- Si no se encuentra la sucursal, generar error
    IF @IdSucursal IS NULL
    BEGIN
        RAISERROR ('La sucursal especificada no existe o la ciudad no es v�lida.', 16, 1);
        RETURN;
    END

    -- Verificar si el DNI ya existe y est� inactivo
    IF EXISTS (SELECT 1 FROM Complementario.Empleados WHERE DecryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12))) = @DNI AND EstaActivo = 0)
    BEGIN
        -- Si el empleado est� inactivo, actualizarlo a activo
        UPDATE Complementario.Empleados
        SET Nombre = @Nombre,
            Apellido = @Apellido,
            DNICifrado = EncryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12)), 1, NULL),  -- Cifrado de DNI
            DireccionCifrada = EncryptByPassPhrase(@FraseClave, @Direccion, 1, NULL),            -- Cifrado de Direcci�n
            EmailPersonalCifrado = EncryptByPassPhrase(@FraseClave, @EmailPersonal, 1, NULL),     -- Cifrado de Email Personal
            EmailEmpresa = @EmailEmpresa,
            CUILCifrado = EncryptByPassPhrase(@FraseClave, @CUIL, 1, NULL),                       -- Cifrado de CUIL
            Cargo = @Cargo,
            IdSucursal = @IdSucursal,
            Turno = @Turno,
            EstaActivo = 1
        WHERE DecryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12))) = @DNI;

        PRINT 'Empleado reactivado con �xito.';
        RETURN;
    END

    -- Si el DNI ya est� activo, generar el error
    IF EXISTS (SELECT 1 FROM Complementario.Empleados WHERE DecryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12))) = @DNI AND EstaActivo = 1)
    BEGIN
        RAISERROR('DNI ya existente', 16, 1);
        RETURN;
    END

    -- Insertar el nuevo empleado
    INSERT INTO Complementario.Empleados (Legajo, Nombre, Apellido, DNICifrado, DireccionCifrada, EmailPersonalCifrado, EmailEmpresa,
                                          CUILCifrado, Cargo, IdSucursal, Turno, EstaActivo)
    VALUES 
        (@Legajo, @Nombre, @Apellido, 
        EncryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12)), 1, NULL),  -- Cifrado de DNI
        EncryptByPassPhrase(@FraseClave, @Direccion, 1, NULL),                -- Cifrado de Direcci�n
        EncryptByPassPhrase(@FraseClave, @EmailPersonal, 1, NULL),            -- Cifrado de Email Personal
        @EmailEmpresa, 
        EncryptByPassPhrase(@FraseClave, @CUIL, 1, NULL),                    -- Cifrado de CUIL
        @Cargo, @IdSucursal, @Turno, 1);

    PRINT 'Empleado agregado con �xito.';
END;
GO

CREATE OR ALTER PROCEDURE Procedimientos.ActualizarEmpleado
    @Legajo INT,
    @Direccion VARCHAR(200) = NULL,
    @EmailPersonal VARCHAR(100) = NULL,
    @Cargo VARCHAR(50) = NULL,
    @Sucursal VARCHAR(50) = NULL,  
    @Turno VARCHAR(25) = NULL,
    @FraseClave NVARCHAR(128)  -- Frase clave para cifrar los datos
AS
BEGIN
	DECLARE @IdSucursal INT;

    SELECT @IdSucursal = IdSucursal
		FROM Complementario.Sucursales
		WHERE ReemplazarPor = @Sucursal;

    IF @IdSucursal IS NULL
    BEGIN
        RAISERROR ('La sucursal especificada no existe o la ciudad no es v�lida.', 16, 1);
        RETURN;
    END

    UPDATE Complementario.Empleados
    SET 
        Cargo = COALESCE(@Cargo, Cargo),
        IdSucursal = COALESCE(@IdSucursal, IdSucursal),						
        Turno = COALESCE(@Turno, Turno),
        DireccionCifrada = COALESCE(EncryptByPassPhrase(@FraseClave, @Direccion, 1, NULL), DireccionCifrada),  -- Cifrado de Direcci�n
        EmailPersonalCifrado = COALESCE(EncryptByPassPhrase(@FraseClave, @EmailPersonal, 1, NULL), EmailPersonalCifrado)  -- Cifrado de Email Personal
    WHERE Legajo = @Legajo;
END;
GO

CREATE ROLE Cajero AUTHORIZATION dbo
CREATE ROLE Supervisor AUTHORIZATION dbo
CREATE ROLE GerenteDeSucursal AUTHORIZATION dbo

GRANT CONTROL ON SCHEMA::NotaCredito TO GerenteDeSucursal
GO

CREATE LOGIN CajeroTest WITH PASSWORD='CajeroTest'
CREATE USER CajeroTest FOR LOGIN CajeroTest
ALTER ROLE Cajero ADD MEMBER CajeroTest

CREATE LOGIN SupervisorTest WITH PASSWORD='SupervisorTest'
CREATE USER SupervisorTest FOR LOGIN SupervisorTest
ALTER ROLE Supervisor ADD MEMBER SupervisorTest

CREATE LOGIN GerenteTest WITH PASSWORD='GerenteTest'
CREATE USER GerenteTest FOR LOGIN GerenteTest
ALTER ROLE GerenteDeSucursal ADD MEMBER GerenteTest