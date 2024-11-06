USE Com5600G01
GO 

CREATE OR ALTER PROCEDURE Procedimientos.Agregar_Factura
	@cantidad INT,
	@tipoCliente CHAR(6),
	@genero CHAR,
	@empleado INT,
	@tipoFactura CHAR,
	@medioDePago CHAR(11),
	@producto VARCHAR(100),
	@ciudad VARCHAR(15),
	@id CHAR(11)
AS
BEGIN
	DECLARE @LineaProd VARCHAR(11)
	DECLARE @sucursal VARCHAR(17)
	DECLARE @precio DECIMAL(6,2)

	-- VERIFICAR EXISTENCIA EMPLEADO
	-- VERIFICAR EXISTENCIA CIUDAD/PRODUCTO

	SELECT @LineaProd = LineaDeProducto from Productos.CatalogoFinal c WHERE c.Nombre = @producto 
	SELECT @sucursal = ReemplazarPor from Complementario.Sucursales s WHERE s.ciudad = @ciudad 
	SELECT @precio = Precio from Productos.CatalogoFinal c WHERE c.Nombre = @producto

	INSERT INTO Ventas.VtasAReg (TipoFactura, TipoCliente, Genero, Cantidad, MedioPago, ciudad, sucursal, LineaDeProducto, Fecha, Hora, Producto, PrecioUni, Id, Empleado)
	VALUES (@tipoFactura, @tipoCliente, @genero, @cantidad, @medioDePago, @ciudad, @sucursal, @LineaProd, GETDATE(), CAST(SYSDATETIME() AS TIME (0)), @producto, @precio, @id, @empleado)
END;
GO

CREATE OR ALTER PROCEDURE Complementario.InsertarEmpleado
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
		1
    );
END;
GO

CREATE PROCEDURE Complementario.BorrarEmpleado
	@Legajo INT
AS 
BEGIN
	UPDATE Complementario.Empleados
	SET EstaActivo = 0
	WHERE Legajo = @Legajo
END;
GO

CREATE PROCEDURE Complementario.ActualizarEmpleado
    @Legajo INT,
    @Direccion VARCHAR(200) = NULL,
    @EmailPersonal VARCHAR(100) = NULL,
    @Cargo VARCHAR(50) = NULL,
    @Sucursal VARCHAR(100) = NULL,
    @Turno VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Complementario.Empleados
    SET Direccion = COALESCE(@Direccion, Direccion),
        EmailPersonal = COALESCE(@EmailPersonal, EmailPersonal),
        Cargo = COALESCE(@Cargo, Cargo),
        Sucursal = COALESCE(@Sucursal, Sucursal),
        Turno = COALESCE(@Turno, Turno)
    WHERE Legajo = @Legajo;
END
GO

CREATE OR ALTER PROCEDURE Procedimientos.EliminarProductoCatalogo
    @nombreProd varchar(100)
AS
BEGIN
    DELETE FROM Productos.CatalogoFinal
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

CREATE OR ALTER PROCEDURE Procedimientos.BorrarMedioDePago
	@id INT
AS
BEGIN
	DELETE FROM Complementario.MediosDePago
	WHERE Id = @id
END;
GO