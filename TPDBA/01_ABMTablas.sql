
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
--Genere store procedures para manejar la inserción, modificado, borrado (si corresponde, también debe decidir si determinadas 
--entidades solo admitirán borrado lógico) de cada tabla. Los nombres de los store procedures NO deben comenzar con “SP”. 

---SP'S PARA ABM DE LAS TABLAS:

USE Com5600G01
GO 

---Creacion de esquemas adicionales para ciertos SP:

DROP SCHEMA IF EXISTS MedioDePago
GO
CREATE SCHEMA MedioDePago
GO
DROP SCHEMA IF EXISTS Ajustes
GO
CREATE SCHEMA Ajustes
GO

-------------SP'S Para Empleados:
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
    @Turno VARCHAR(25)
AS
BEGIN
    -- Verifica si el DNI ya existe y si esta inactivo
    IF EXISTS (SELECT 1 FROM Sucursal.Empleados WHERE DNI = @DNI AND EstaActivo = 0)
    BEGIN
        -- Si el empleado esta inactivo, lo pasa a activo
        UPDATE Sucursal.Empleados
        SET Nombre = @Nombre,
            Apellido = @Apellido,
            Direccion = @Direccion,
            EmailPersonal = @EmailPersonal,
            EmailEmpresa = @EmailEmpresa,
            CUIL = @CUIL,
            Cargo = @Cargo,
            Turno = @Turno,
            EstaActivo = 1
        WHERE DNI = @DNI;

        PRINT 'Empleado reactivado con éxito.';
        RETURN;
    END

    -- Si el DNI ya esta activo, retorna error
    IF EXISTS (SELECT 1 FROM Sucursal.Empleados WHERE DNI = @DNI AND EstaActivo = 1)
    BEGIN
        RAISERROR('DNI ya existente', 16, 1);
        RETURN;
    END

    DECLARE @IdSucursal INT;

    -- Obtiene el ID sucursal
    SELECT @IdSucursal = IdSucursal
    FROM Sucursal.Sucursales
    WHERE ReemplazarPor = @Sucursal;

    -- Si no se encuentra la sucursal, retorna error
    IF @IdSucursal IS NULL
    BEGIN
        RAISERROR ('La sucursal especificada no existe o la ciudad no es válida.', 16, 1);
        RETURN;
    END

    -- Obtiene proximo legajo
    DECLARE @Legajo INT
    SELECT @Legajo = MAX(Legajo) + 1
    FROM Sucursal.Empleados;

    -- Inserta nuevo empleado
    INSERT INTO Sucursal.Empleados
        (Legajo, Nombre, Apellido, DNI, Direccion, EmailPersonal, EmailEmpresa, CUIL, Cargo, IdSucursal, Turno, EstaActivo)
    VALUES
        (@Legajo, @Nombre, @Apellido, @DNI, @Direccion, @EmailPersonal, @EmailEmpresa, @CUIL, @Cargo, @IdSucursal, @Turno, 1);

    PRINT 'Empleado agregado con éxito.';
END;
GO

CREATE OR ALTER PROCEDURE Sucursal.ActualizarEmpleado
    @Legajo INT,
    @Direccion VARCHAR(200) = NULL,
    @EmailPersonal VARCHAR(100) = NULL,
    @Cargo VARCHAR(50) = NULL,
    @Sucursal VARCHAR(50) = NULL,  
    @Turno VARCHAR(25) = NULL
AS
BEGIN
	DECLARE @IdSucursal INT;

    SELECT @IdSucursal = IdSucursal
	FROM Sucursal.Sucursales
	WHERE ReemplazarPor = @Sucursal;
	IF NOT EXISTS (SELECT 1 FROM Sucursal.Empleados e WHERE e.Legajo = @Legajo)
	BEGIN
        RAISERROR ('No existe ese empleado', 16, 1);
        RETURN;
    END

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
        Direccion = COALESCE(@Direccion, Direccion),
        EmailPersonal = COALESCE(@EmailPersonal, EmailPersonal)
    WHERE Legajo = @Legajo;
	PRINT 'Se actualizo el empleado con legajo ' + CAST(@legajo AS CHAR)
END;
GO

CREATE OR ALTER PROCEDURE Sucursal.EliminarEmpleado
	@Legajo INT
AS 
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Sucursal.Empleados e WHERE e.Legajo = @Legajo)
	BEGIN
        RAISERROR ('No existe ese empleado', 16, 1);
        RETURN;
    END

	UPDATE Sucursal.Empleados
	SET EstaActivo = 0
	WHERE Legajo = @Legajo
END;
GO

-------------SP'S para Categoria de Productos:
CREATE OR ALTER PROCEDURE Productos.AgregarCategoria
	@NombreLinea VARCHAR(100),
	@NombreProd	VARCHAR(100)
AS
BEGIN
		IF EXISTS (SELECT 1 FROM Productos.CategoriaDeProds c WHERE c.LineaDeProducto = @NombreLinea AND c.Producto = @NombreProd)
		BEGIN
			RAISERROR ('Esa Categoria YA existe',16,1);
			RETURN;
		END

		INSERT INTO Productos.CategoriaDeProds(LineaDeProducto,Producto)
		VALUES(@NombreLinea,@NombreProd)

END;
GO

CREATE OR ALTER PROCEDURE Productos.EliminarCategoria
	@NombreLinea VARCHAR(100),
	@NombreProd	VARCHAR(100)
AS
BEGIN
	DECLARE @IdCat INT
	SELECT @IdCat = c.Id FROM Productos.CategoriaDeProds c WHERE c.LineaDeProducto = @NombreLinea AND c.Producto = @NombreProd
	IF @IdCat IS NULL 
		BEGIN
			RAISERROR ('Esa Categoria NO existe',16,1);
			RETURN;
		END
	
	DELETE FROM Productos.CategoriaDeProds
	WHERE Id = @IdCat

END;
GO

-------------SP'S para Productos:
CREATE OR ALTER PROCEDURE Productos.AgregarOActualizarProductoCatalogo
    @Nombre VARCHAR(100),
    @Precio DECIMAL(6,2),
    @IdCategoria INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Productos.CategoriaDeProds WHERE Id = @IdCategoria)
    BEGIN
        RAISERROR('Esa categoria NO existe', 16, 1)
        RETURN;
    END
    IF EXISTS (                                                            -- Comprueba si ya existe el producto en el catálogo
        SELECT 1
        FROM Productos.Catalogo
        WHERE Nombre = @Nombre AND IdCategoria = @IdCategoria
    )
    BEGIN
        UPDATE Productos.Catalogo                                        -- Si existe, actualiza el precio
        SET Precio = @Precio
        WHERE Nombre = @Nombre AND IdCategoria = @IdCategoria;
    END
    ELSE
    BEGIN
        INSERT INTO Productos.Catalogo (Nombre, Precio, IdCategoria)    -- Si no existe, inserta el nuevo producto
        VALUES (@Nombre, @Precio, @IdCategoria);
    END
    PRINT 'Se agrego/actualizo el producto ' + @nombre
END;
GO

CREATE OR ALTER PROCEDURE Productos.EliminarProducto
    @Id INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM Productos.Catalogo WHERE Id = @id)
	BEGIN
        RAISERROR ('No existe ese producto', 16, 1);
        RETURN;
    END

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
	IF NOT EXISTS (SELECT 1 FROM Complementario.MediosDePago WHERE IdMDP = @id)
	BEGIN
        RAISERROR ('No existe ese medio de pago', 16, 1);
        RETURN;
    END

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
        FROM Sucursal.Sucursales
        WHERE Ciudad = @Ciudad AND Direccion = @Direccion AND ReemplazarPor = @ReemplazarPor
    )
    BEGIN
        RAISERROR ('Ya existe esa sucursal', 16, 1);
        RETURN;
    END
    INSERT INTO Sucursal.Sucursales (Ciudad, ReemplazarPor, Direccion, Horario, Telefono)	-- Inserta la nueva sucursal si no existe
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
    UPDATE Sucursal.Sucursales							-- Actualiza solo los campos que no son NULL
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
	IF NOT EXISTS (SELECT 1 FROM Sucursal.Sucursales WHERE IdSucursal = @id)
	BEGIN
        RAISERROR ('No existe esa sucursal', 16, 1);
        RETURN;
    END
	DELETE FROM Sucursal.Sucursales
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
    DECLARE @PrecioUnitario DECIMAL(6, 2),
            @IdCategoria INT,
            @CantidadRestante INT;

    -- Obtiene precio unitario, categoría y cantidad disponible en la factura
    SELECT @PrecioUnitario = dv.PrecioUnitario, 
           @IdCategoria = dv.IdCategoria,
           @CantidadRestante = dv.Cantidad  -- Obtiene la cantidad actual en DetalleVentas
    FROM Ventas.DetalleVentas dv
    WHERE dv.IdFactura = @IdFactura
      AND dv.IdProducto = @IdProducto;

    -- Verifica que exista el producto en la factura y que la cantidad sea suficiente
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

    INSERT INTO NotaCredito.NotasDeCredito (IdProd, IdFactura, EstadoActivo, Cantidad, IdCategoria, Precio)
    VALUES (@IdProducto, 
            @IdFactura, 
            1,									-- Estado activo
            @Cantidad, 
            @IdCategoria, 
            @PrecioUnitario * @Cantidad); 

    UPDATE Ventas.DetalleVentas
    SET Cantidad = Cantidad - @Cantidad
    WHERE IdFactura = @IdFactura
      AND IdProducto = @IdProducto;

    PRINT 'Nota de crédito generada con éxito.';
END;
GO

CREATE OR ALTER PROCEDURE NotaCredito.EliminarNotaCredito
    @Id INT
AS
BEGIN
    UPDATE NotaCredito.NotasDeCredito
    SET EstadoActivo = 0
    WHERE Id = @Id;
END;
GO

-------------SP'S Para Clientes:
CREATE OR ALTER PROCEDURE Ventas.AgregarCliente
    @Nombre VARCHAR(50),
    @Genero CHAR(6),
	@DNI INT
AS
BEGIN
        IF EXISTS (SELECT 1 FROM Ventas.Clientes WHERE DNI = @DNI) -- Inserta el cliente en la tabla solo si no está su dni ya ingresado
        BEGIN
            RAISERROR('Ya existe un cliente con el DNI ingresado.', 16, 1);
            RETURN;
        END

        INSERT INTO Ventas.Clientes (Nombre, TipoCliente, Genero, DNI)
        VALUES (@Nombre, 'Member', @Genero, @DNI);
END;
GO

CREATE OR ALTER PROCEDURE Ventas.ModificarCliente
	@IdCliente INT,
	@TipoClienteNuevo CHAR(6)
AS
BEGIN
      IF NOT EXISTS (SELECT 1 FROM Ventas.Clientes WHERE IdCliente = @IdCliente)
      BEGIN
           RAISERROR('No existe un cliente con el ID ingresado.', 16, 1);
		   RETURN;
      END
      
	  UPDATE Ventas.Clientes
      SET TipoCliente = @TipoClienteNuevo
      WHERE IdCliente = @IdCliente;
END;
GO

CREATE OR ALTER PROCEDURE Ventas.EliminarCliente
    @IdCliente INT
AS
BEGIN
       IF NOT EXISTS (SELECT 1 FROM Ventas.Clientes WHERE IdCliente = @IdCliente)
       BEGIN
            RAISERROR('No existe un cliente con el ID ingresado.', 16, 1);
            RETURN;
       END

       DELETE FROM Ventas.Clientes
       WHERE IdCliente = @IdCliente;   
END;
GO

-------------SP'S para Detalles de Ventas:
CREATE OR ALTER PROCEDURE Ventas.AgregarProducto
    @IdProducto INT
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Productos.Catalogo WHERE Id = @IdProducto)
        BEGIN
            -- Lanza una excepcion para que la transaccion haga ROLLBACK
            THROW 50001, 'El producto no existe en el catálogo.', 1;
        END;

        IF NOT EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '##DetalleVentas')
        BEGIN
            CREATE TABLE ##DetalleVentas
            (
                IdDetalle INT IDENTITY(1,1) PRIMARY KEY,  -- ID auto incrementable como clave primaria
                IdProducto INT,                            -- Relación con el producto
                Cantidad INT                               -- Cantidad de producto
            );
        END;

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
        END;
    END TRY
    BEGIN CATCH
        THROW; -- Lanza la excepcion para que el bloque de transaccion externo haga el ROLLBACK
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Ventas.FinalizarCompra
    @IdFactura INT 
AS
BEGIN
    INSERT INTO Ventas.DetalleVentas (IdFactura, IdProducto, IdCategoria, Cantidad, PrecioUnitario, Moneda)
    SELECT
        @IdFactura,                             
        d.IdProducto,                            
        p.IdCategoria,                         
        d.Cantidad,                             
        p.Precio,
		'ARS' AS Moneda
    FROM ##DetalleVentas d
    JOIN Productos.Catalogo p ON d.IdProducto = p.Id;  

    DROP TABLE ##DetalleVentas;
END;
GO

CREATE OR ALTER PROCEDURE Ventas.CancelarCompra
AS
BEGIN
    RAISERROR ('Compra cancelada por el usuario.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE Ventas.CargarFacturas
    @IdCliente INT,
    @IdSucursal INT,
    @Empleado INT,
    @TipoFactura CHAR(1),
    @IdMedioPago INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Complementario.MediosDePago WHERE IdMDP = @IdMedioPago)
    BEGIN
        RAISERROR ('El medio de pago no existe.', 16, 1);
        RETURN;
    END

    IF @TipoFactura NOT IN ('A', 'B', 'C')
    BEGIN
        RAISERROR ('El tipo de factura no es válido. Debe ser A, B o C.', 16, 1);
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