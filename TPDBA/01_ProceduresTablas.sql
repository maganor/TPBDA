---ABM:

USE Com5600G01
GO 

DROP SCHEMA IF EXISTS Procedimientos
GO
CREATE SCHEMA Procedimientos 
GO

DROP SCHEMA IF EXISTS Empleado
GO
CREATE SCHEMA Empleado
GO

DROP SCHEMA IF EXISTS Cliente
GO
CREATE SCHEMA Cliente
GO

DROP SCHEMA IF EXISTS Producto
GO
CREATE SCHEMA Producto
GO

DROP SCHEMA IF EXISTS MedioDePago
GO
CREATE SCHEMA MedioDePago
GO

DROP SCHEMA IF EXISTS Sucursal
GO
CREATE SCHEMA Sucursal
GO

DROP SCHEMA IF EXISTS NotaCredito
GO
CREATE SCHEMA NotaCredito
GO

DROP SCHEMA IF EXISTS DetalleVenta
GO
CREATE SCHEMA DetalleVenta
GO

-------------SP'S Para Empleados:
CREATE OR ALTER PROCEDURE Empleado.AgregarEmpleado
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

	DECLARE @Legajo INT
	SELECT @Legajo =  MAX(Legajo) + 1 from Complementario.Empleados 
	   
    INSERT INTO Complementario.Empleados 
        (Legajo, Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo, IdSucursal, Turno, EstaActivo)
    VALUES 
        (@Legajo, @Nombre, @Apellido, @DNI, @Direccion, @EmailPersonal, @EmailEmpresa, @CUIL, @Cargo, @IdSucursal, @Turno, 1);
END;
GO

CREATE OR ALTER PROCEDURE Empleado.ActualizarEmpleado
    @Legajo INT,
    @Direccion VARCHAR(200) = NULL,
    @EmailPersonal VARCHAR(100) = NULL,
    @Cargo VARCHAR(50) = NULL,
    @IdSucursal INT = NULL,  
    @Turno VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	IF @IdSucursal IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Complementario.Sucursales WHERE IdSucursal = @IdSucursal)
    BEGIN
        RAISERROR('El ID de Sucursal proporcionado no existe.', 16, 1);
        RETURN;
    END
    UPDATE Complementario.Empleados										
    SET 
        Cargo = COALESCE(@Cargo, Cargo),
        IdSucursal = COALESCE(@IdSucursal, IdSucursal),						
        Turno = COALESCE(@Turno, Turno),
        Direccion = COALESCE(@Direccion, Direccion),
        EmailPersonal = COALESCE(@EmailPersonal, EmailPersonal)
    WHERE Legajo = @Legajo;
	PRINT 'Se actualizo el empleado con legajo ' + @legajo
END;
GO

CREATE OR ALTER PROCEDURE Empleado.EliminarEmpleado
	@Legajo INT
AS 
BEGIN
	UPDATE Complementario.Empleados
	SET EstaActivo = 0
	WHERE Legajo = @Legajo
END;
GO

-------------SP'S para Productos:
CREATE OR ALTER PROCEDURE Producto.AgregarOActualizarProductoCatalogo
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
	PRINT 'Se agrego/actualizo el producto ' + @nombre
END;
GO

CREATE OR ALTER PROCEDURE Producto.EliminarProducto
    @Id INT
AS
BEGIN
    DELETE FROM Productos.Catalogo
    WHERE Id = @Id

END;
GO
-------------SP'S para Medios de Pago:
CREATE OR ALTER PROCEDURE MedioDePago.AgregarMedioDePago
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

CREATE OR ALTER PROCEDURE MedioDePago.EliminarMedioDePago
	@id INT
AS
BEGIN
	DELETE FROM Complementario.MediosDePago
	WHERE IdMDP = @id
END;
GO
-------------SP'S Para Sucursales:
CREATE OR ALTER PROCEDURE Sucursal.AgregarSucursal
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

CREATE OR ALTER PROCEDURE Sucursal.ActualizarSucursal
    @IdSucursal INT,                  
    @Direccion VARCHAR(200) = NULL,     --Si no se le envian parametros, toman el valor NULL
    @Telefono VARCHAR(20) = NULL,       
    @Horario VARCHAR(100) = NULL        
AS
BEGIN
    UPDATE Complementario.Sucursales							-- Actualiza solo los campos que no son NULL
    SET 
        Direccion = COALESCE(@Direccion, Direccion),		
        Telefono = COALESCE(@Telefono, Telefono),			
        Horario = COALESCE(@Horario, Horario)				
    WHERE IdSucursal = @IdSucursal;
END;
GO

CREATE OR ALTER PROCEDURE Sucursal.EliminarSucursal
	@id int
AS
BEGIN
	DELETE FROM Complementario.Sucursales
	WHERE IdSucursal = @id
END;
GO

-------------SP'S Para Notas de Credito:

CREATE OR ALTER PROCEDURE NotaCredito.GenerarNotaCredito
    @IdFactura INT,
    @IdProducto INT,
    @Cantidad INT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM Ventas.DetalleVentas dv
        WHERE dv.IdFactura = @IdFactura
        AND dv.IdProducto = @IdProducto
        AND dv.Cantidad >= @Cantidad
    )
    BEGIN
        RAISERROR ('No se puede procesar la devolución. Verifique la factura, el producto y la cantidad.', 16, 1);
        RETURN;
    END

    DECLARE @PrecioUnitario DECIMAL(6, 2),
            @IdCategoria INT;

    SELECT @PrecioUnitario = dv.PrecioUnitario, 
           @IdCategoria = dv.IdCategoria
    FROM Ventas.DetalleVentas dv
    WHERE dv.IdFactura = @IdFactura
      AND dv.IdProducto = @IdProducto;

    INSERT INTO Ventas.NotasDeCredito (IdProd, IdFactura, EstadoActivo, Cantidad, IdCategoria, Precio)
    VALUES (@IdProducto, 
            @IdFactura, 
            1,								-- Estado activo
            @Cantidad, 
            @IdCategoria, 
            @PrecioUnitario * @Cantidad); 

    PRINT 'Nota de crédito generada con éxito.';
END;
GO

CREATE OR ALTER PROCEDURE NotaCredito.EliminarNotaCredito
    @Id INT
AS
BEGIN
    UPDATE Ventas.NotasDeCredito
    SET EstadoActivo = 0
    WHERE Id = @Id;
END;
GO

-------------SP'S Para Clientes:
CREATE OR ALTER PROCEDURE Cliente.AgregarCliente
    @Nombre VARCHAR(50),
    @Genero CHAR(6),
	@DNI INT
AS
BEGIN
        IF EXISTS (SELECT 1 FROM Complementario.Clientes WHERE DNI = @DNI) -- Inserta el cliente en la tabla solo si no está su dni ya ingresado
        BEGIN
            RAISERROR('Ya existe un cliente con el DNI ingresado.', 16, 1);
            RETURN;
        END

        INSERT INTO Complementario.Clientes (Nombre, TipoCliente, Genero, DNI)
        VALUES (@Nombre, 'Member', @Genero, @DNI);
END;
GO

CREATE OR ALTER PROCEDURE Cliente.ModificarCliente
	@IdCliente INT,
	@TipoClienteNuevo CHAR(6)
AS
BEGIN
      IF NOT EXISTS (SELECT 1 FROM Complementario.Clientes WHERE IdCliente = @IdCliente)
      BEGIN
           RAISERROR('No existe un cliente con el ID ingresado.', 16, 1);
		   RETURN;
      END
      
	  UPDATE Complementario.Clientes
      SET TipoCliente = @TipoClienteNuevo
      WHERE IdCliente = @IdCliente;
END;
GO

CREATE OR ALTER PROCEDURE Cliente.EliminarCliente
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

-------------SP'S para Detalles de Ventas:
CREATE OR ALTER PROCEDURE DetalleVenta.AgregarProducto
    @IdProducto INT
AS
BEGIN

	IF NOT EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##DetalleVentas')
	BEGIN
	CREATE TABLE ##DetalleVentas
	(
		IdDetalle INT IDENTITY(1,1) PRIMARY KEY,  -- ID auto incrementable como clave primaria
		IdProducto INT,                            -- Relación con el producto
		Cantidad INT                               -- Cantidad de producto
	);
	END

    IF EXISTS (SELECT 1 FROM ##DetalleVentas WHERE IdProducto = @IdProducto)
    BEGIN
        UPDATE ##DetalleVentas
        SET Cantidad = Cantidad + 1
        WHERE IdProducto = @IdProducto;
    END
    ELSE
    BEGIN
        INSERT INTO ##DetalleVentas (IdProducto, Cantidad)
        VALUES (@IdProducto, 1);
    END
END;
GO

CREATE OR ALTER PROCEDURE DetalleVenta.FinalizarCompra
    @IdFactura INT 
AS
BEGIN
    INSERT INTO Ventas.DetalleVentas (IdFactura, IdProducto, IdCategoria, Cantidad, PrecioUnitario)
    SELECT
        @IdFactura,                             
        d.IdProducto,                            
        p.IdCategoria,                         
        d.Cantidad,                             
        p.Precio
    FROM ##DetalleVentas d
    JOIN Productos.Catalogo p ON d.IdProducto = p.Id;  

    DROP TABLE ##DetalleVentas;
END;
GO

CREATE OR ALTER PROCEDURE DetalleVenta.CancelarCompra
AS
BEGIN
    RAISERROR ('Compra cancelada por el usuario.', 16, 1);
END;
GO


CREATE OR ALTER PROCEDURE DetalleVenta.CargarFacturas
    @IdCliente INT,
    @IdSucursal INT,
    @Empleado INT,
    @TipoFactura CHAR(1),
    @IdMedioPago INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Complementario.MediosDePago WHERE IdMDP = @IdMedioPago)
    BEGIN
        RAISERROR ('El medio de pago no existe.', 16, 1); -- Código de error 16
        RETURN;
    END

    IF @TipoFactura NOT IN ('A', 'B', 'C')
    BEGIN
        RAISERROR ('El tipo de factura no es válido. Debe ser A, B o C.', 16, 1); -- Código de error 16
        RETURN;
    END

    INSERT INTO Ventas.Facturas (TipoFactura, Fecha, Hora, IdMedioPago, Empleado, IdSucursal, IdCliente)
    VALUES 
    (
        @TipoFactura,                              
        GETDATE(),                                
        CONVERT(TIME(0), GETDATE()),              
        @IdMedioPago,                             
        @Empleado,                             
        @IdSucursal,                              
        @IdCliente                                
    );

    PRINT 'Factura cargada correctamente.';
END;
GO

-------------SP'S para el Valor Actual del Dolar:
CREATE OR ALTER PROCEDURE Procedimientos.CargarValorDolar
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables para manejar la respuesta de la API
    DECLARE @url NVARCHAR(64) = 'https://dolarapi.com/v1/dolares/blue'; -- URL del API
    DECLARE @Object INT; -- Objeto para la llamada HTTP
    DECLARE @json TABLE(DATA NVARCHAR(MAX)); -- Tabla para almacenar la respuesta
    DECLARE @respuesta NVARCHAR(MAX); -- Variable para almacenar el JSON de la respuesta
    DECLARE @Venta DECIMAL(6,2); -- Variable para almacenar el valor de venta del dólar

    -- Crear el objeto para la llamada HTTP
    EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;

    -- Realizar la solicitud GET al API
    EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';
    EXEC sp_OAMethod @Object, 'SEND';
    EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT;

    -- Insertar la respuesta del JSON en la tabla temporal
    INSERT INTO @json
    EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';

    -- Extraer el valor de "venta" del JSON
    SELECT @Venta = JSON_VALUE(DATA, '$.venta') FROM @json;

    -- Intentar actualizar el valor del dólar en la tabla
    UPDATE Complementario.ValorDolar
    SET PrecioAR = @Venta, FechaHora = SYSDATETIME()
    WHERE FechaHora = (SELECT MAX(FechaHora) FROM Complementario.ValorDolar);

    -- Si no se actualizó ninguna fila, insertar un nuevo registro
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO Complementario.ValorDolar (PrecioAR, FechaHora)
        VALUES (@Venta, SYSDATETIME());
    END

    -- Limpiar el objeto COM
    EXEC sp_OADestroy @Object;

END;
GO
