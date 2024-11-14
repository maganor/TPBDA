USE Com5600G01	

SELECT * FROM Complementario.Empleados
EXEC Procedimientos.TransferirEmpleadosCifrados @FraseClave = 'AvenidaSiempreViva742'		--Frase clave para cifrar los datos
SELECT * FROM Complementario.Empleados

EXEC Procedimientos.AgregarEmpleado		@Nombre = 'Marcelo',
										@Apellido = 'Gallardo',
										@DNI = '09121831',
										@Direccion = 'Av. Pdte. Figueroa Alcorta 7597',
										@EmailPersonal = 'gallardo912@gmail.com',   
										@EmailEmpresa = 'gallardoaurora@gmail.com',
										@CUIL = '20-09121831-3',
										@Cargo = 'Cajero',
										@Sucursal = 'San Justo',
										@Turno = 'TM',
										@FraseClave = 'AvenidaSiempreViva742'
GO

SELECT * FROM Complementario.Empleados

EXEC Procedimientos.ActualizarEmpleado	@Legajo = '257036',
										@Direccion = 'enrique segoviano 1944',
										@EmailPersonal = 'Bombaloca@gmail.com',
										@Cargo = 'Gerente de sucursal',
										@Sucursal = 'San Justo',
										@Turno = 'Jornada completa',
										@FraseClave = 'AvenidaSiempreViva742'
GO	

SELECT * FROM Complementario.Empleados



EXECUTE AS USER = 'CajeroTest'
	EXEC NotaCredito.EliminarNotaCredito @id = 1
REVERT

EXECUTE AS USER = 'GerenteTest'
	EXEC NotaCredito.EliminarNotaCredito @id = 1
REVERT
