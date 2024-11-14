USE Com5600G01	
GO

------------LOGINS, USUARIOS Y ROLES:

CREATE ROLE Cajero AUTHORIZATION dbo
CREATE ROLE Supervisor AUTHORIZATION dbo
CREATE ROLE GerenteDeSucursal AUTHORIZATION dbo

GRANT CONTROL ON SCHEMA::Productos TO Cajero,Supervisor,GerenteDeSucursal;
GRANT CONTROL ON SCHEMA::Ventas TO Cajero,Supervisor,GerenteDeSucursal;
GRANT CONTROL ON SCHEMA::Complementario TO Supervisor,GerenteDeSucursal;
GRANT CONTROL ON SCHEMA::MedioDePago TO Supervisor,GerenteDeSucursal;
GRANT CONTROL ON SCHEMA::Ajustes TO Supervisor,GerenteDeSucursal;
GRANT CONTROL ON SCHEMA::NotaCredito TO Supervisor
GRANT CONTROL ON SCHEMA::Reportes TO Supervisor
GRANT CONTROL ON SCHEMA::Sucursal TO GerenteDeSucursal;

GO

CREATE LOGIN CajeroTest WITH PASSWORD='CajeroTest', DEFAULT_DATABASE = Com5600G01
CREATE USER CajeroTest FOR LOGIN CajeroTest
ALTER ROLE Cajero ADD MEMBER CajeroTest

CREATE LOGIN SupervisorTest WITH PASSWORD='SupervisorTest', DEFAULT_DATABASE = Com5600G01
CREATE USER SupervisorTest FOR LOGIN SupervisorTest
ALTER ROLE Supervisor ADD MEMBER SupervisorTest

CREATE LOGIN GerenteTest WITH PASSWORD='GerenteTest', DEFAULT_DATABASE = Com5600G01
CREATE USER GerenteTest FOR LOGIN GerenteTest
ALTER ROLE GerenteDeSucursal ADD MEMBER GerenteTest


------------CIFRADO:

DROP SCHEMA IF EXISTS Cifrado
GO
CREATE SCHEMA Cifrado
GO

------SP para cifrar agregar los campos cifrados:

CREATE OR ALTER PROCEDURE Cifrado.PrepararTablaParaCifrar
AS
BEGIN
	ALTER TABLE Sucursal.Empleados ADD DNICifrado VARBINARY(256)
	ALTER TABLE Sucursal.Empleados ADD DireccionCifrada VARBINARY(256)
	ALTER TABLE Sucursal.Empleados ADD EmailPersonalCifrado VARBINARY(256)
	ALTER TABLE Sucursal.Empleados ADD CUILCifrado VARBINARY(256)
END
GO 

EXEC Cifrado.PrepararTablaParaCifrar
GO

-----SP para el pasaje de los campos sin cifrar a los que estan cifrados:

CREATE OR ALTER PROCEDURE Cifrado.TransferirEmpleadosCifrados
	@FraseClave NVARCHAR(128)
AS
BEGIN
	--Se hace el pasaje de los campos sin cifrar a los cifrados (solo algunos campos "sensibles")
    UPDATE Sucursal.Empleados
    SET 
        DNICifrado = EncryptByPassPhrase(@FraseClave, CAST(DNI AS VARCHAR(12)), 1, NULL),
        DireccionCifrada = EncryptByPassPhrase(@FraseClave, Direccion, 1, NULL),
        EmailPersonalCifrado = EncryptByPassPhrase(@FraseClave, EmailPersonal, 1, NULL),
        CUILCifrado = EncryptByPassPhrase(@FraseClave, CUIL, 1, NULL)

	 ALTER TABLE Sucursal.Empleados DROP COLUMN DNI
     ALTER TABLE Sucursal.Empleados DROP COLUMN Direccion
     ALTER TABLE Sucursal.Empleados DROP COLUMN EmailPersonal
     ALTER TABLE Sucursal.Empleados DROP COLUMN CUIL

END;
GO

-----"Mejora" para el SP de AgregarEmpleado:

CREATE OR ALTER PROCEDURE Sucursal.AgregarEmpleado
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

    -- Obtiene el IdSucursal para la sucursal especificada
    SELECT @IdSucursal = IdSucursal
    FROM Sucursal.Sucursales
    WHERE ReemplazarPor = @Sucursal;

	DECLARE @Legajo INT
    SELECT @Legajo = MAX(Legajo) + 1
    FROM Sucursal.Empleados;

    -- Si no se encuentra la sucursal, retorna error
    IF @IdSucursal IS NULL
    BEGIN
        RAISERROR ('La sucursal especificada no existe o la ciudad no es válida.', 16, 1);
        RETURN;
    END

    -- Verificar si el DNI ya existe y está inactivo
    IF EXISTS (SELECT 1 FROM Sucursal.Empleados WHERE DecryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12))) = @DNI AND EstaActivo = 0)
    BEGIN
        -- Si el empleado está inactivo, lo pasa a activo
        UPDATE Sucursal.Empleados
        SET Nombre = @Nombre,
            Apellido = @Apellido,
            DNICifrado = EncryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12)), 1, NULL),  -- Cifrado de DNI
            DireccionCifrada = EncryptByPassPhrase(@FraseClave, @Direccion, 1, NULL),            -- Cifrado de Dirección
            EmailPersonalCifrado = EncryptByPassPhrase(@FraseClave, @EmailPersonal, 1, NULL),     -- Cifrado de Email Personal
            EmailEmpresa = @EmailEmpresa,
            CUILCifrado = EncryptByPassPhrase(@FraseClave, @CUIL, 1, NULL),                       -- Cifrado de CUIL
            Cargo = @Cargo,
            IdSucursal = @IdSucursal,
            Turno = @Turno,
            EstaActivo = 1
        WHERE DecryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12))) = @DNI;

        PRINT 'Empleado reactivado con éxito.';
        RETURN;
    END

    -- Si el DNI ya está activo, retorna el error
    IF EXISTS (SELECT 1 FROM Sucursal.Empleados WHERE DecryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12))) = @DNI AND EstaActivo = 1)
    BEGIN
        RAISERROR('DNI ya existente', 16, 1);
        RETURN;
    END

    -- Inserta el nuevo empleado
    INSERT INTO Sucursal.Empleados (Legajo, Nombre, Apellido, DNICifrado, DireccionCifrada, EmailPersonalCifrado, EmailEmpresa,
                                          CUILCifrado, Cargo, IdSucursal, Turno, EstaActivo)
    VALUES 
        (@Legajo, @Nombre, @Apellido, 
        EncryptByPassPhrase(@FraseClave, CAST(@DNI AS VARCHAR(12)), 1, NULL),  -- Cifrado de DNI
        EncryptByPassPhrase(@FraseClave, @Direccion, 1, NULL),                -- Cifrado de Dirección
        EncryptByPassPhrase(@FraseClave, @EmailPersonal, 1, NULL),            -- Cifrado de Email Personal
        @EmailEmpresa, 
        EncryptByPassPhrase(@FraseClave, @CUIL, 1, NULL),                    -- Cifrado de CUIL
        @Cargo, @IdSucursal, @Turno, 1);

    PRINT 'Empleado agregado con éxito.';
END;
GO

-----"Mejora" para el SP de ActualizarEmpleado:

CREATE OR ALTER PROCEDURE Sucursal.ActualizarEmpleado
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
		FROM Sucursal.Sucursales
		WHERE ReemplazarPor = @Sucursal;

    IF @IdSucursal IS NULL
    BEGIN
        RAISERROR ('La sucursal especificada no existe o la ciudad no es válida.', 16, 1);
        RETURN;
    END

    UPDATE Sucursal.Empleados
    SET 
        Cargo = COALESCE(@Cargo, Cargo),
        IdSucursal = COALESCE(@IdSucursal, IdSucursal),						
        Turno = COALESCE(@Turno, Turno),
        DireccionCifrada = COALESCE(EncryptByPassPhrase(@FraseClave, @Direccion, 1, NULL), DireccionCifrada),  -- Cifrado de Dirección
        EmailPersonalCifrado = COALESCE(EncryptByPassPhrase(@FraseClave, @EmailPersonal, 1, NULL), EmailPersonalCifrado)  -- Cifrado de Email Personal
    WHERE Legajo = @Legajo;
END;
GO

-----"Mejora" para el SP de Carga del archivo de Empleados:

CREATE OR ALTER PROCEDURE Carga.CargarEmpleados
    @direccion VARCHAR(100),
    @FraseClave NVARCHAR(128)  -- Agregamos la frase clave para la encriptación
AS
BEGIN
    PRINT 'Procesando Empleados';
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #EmpleadosTemp;
    CREATE TABLE #EmpleadosTemp (
        Legajo INT,
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
        EstaActivo BIT DEFAULT 1
    );

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'
    INSERT INTO #EmpleadosTemp (Legajo, Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo, Sucursal, Turno, EstaActivo)
    SELECT 
        CAST([Legajo/ID] AS INT),
        CAST(Nombre AS VARCHAR(50)),
        CAST(Apellido AS VARCHAR(50)),
        CAST(DNI AS INT),
        CAST(Direccion AS VARCHAR(200)),
        CAST([email personal] AS VARCHAR(100)),
        CAST([email empresa] AS VARCHAR(100)),
        CAST(CUIL AS VARCHAR(11)),
        CAST(Cargo AS VARCHAR(50)),
        CAST(Sucursal AS VARCHAR(100)),
        CAST(Turno AS VARCHAR(25)),
        1  -- Valor predeterminado para EstaActivo
    FROM OPENROWSET(
        ''Microsoft.ACE.OLEDB.12.0'',
        ''Excel 12.0; Database=' + @direccion + '; HDR=YES;'', 
        ''SELECT * FROM [Empleados$] WHERE [Legajo/ID] IS NOT NULL''
    );';

    EXEC sp_executesql @sql;

    SET NOCOUNT OFF;
    
    -- Inserta los empleados en la tabla final teniendo en cuenta el cifrado
    INSERT INTO Sucursal.Empleados (Legajo,Nombre,Apellido,DNICifrado,DireccionCifrada,EmailPersonalCifrado,EmailEmpresa,CUILCifrado,Cargo,IdSucursal,Turno,EstaActivo)
    SELECT e.Legajo,e.Nombre,e.Apellido,
		EncryptByPassPhrase(@FraseClave, CAST(e.DNI AS VARCHAR(12)), 1, NULL) AS DNICifrado,
        EncryptByPassPhrase(@FraseClave, e.Direccion, 1, NULL) AS DireccionCifrada,
        EncryptByPassPhrase(@FraseClave, e.EmailPersonal, 1, NULL) AS EmailPersonalCifrado,
        e.EmailEmpresa,
        EncryptByPassPhrase(@FraseClave, e.CUIL, 1, NULL) AS CUILCifrado,
        e.Cargo,s.IdSucursal,e.Turno,e.EstaActivo
    
	FROM #EmpleadosTemp e
		JOIN Sucursal.Sucursales s ON s.ReemplazarPor = e.Sucursal
    
	WHERE NOT EXISTS (SELECT 1 FROM Sucursal.Empleados c WHERE c.Legajo = e.Legajo);
    
	DROP TABLE #EmpleadosTemp;

END;
GO