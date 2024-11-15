
--Trabajo Practico Integrador - Bases de Datos Aplicada:
--Fecha de Entrega: 15/11/2024
--Comisión: 02-5600
--Grupo: 01
--Integrantes:
--Antola Ortiz, Mauricio Gabriel  -       44613237 
--Tempra, Francisco               -       44485891
--Villegas Brandolini, Lucas      -       44459666
--Zapata, Santiago                -       44525943


USE Com5600G01	

-------TESTING PARA NOTA DE CREDITO CON ROLES:

	SELECT * FROM NotaCredito.NotasDeCredito

	EXEC NotaCredito.GenerarNotaCredito		@IdProducto = 104,
											@IdFactura = 1001,
											@Cantidad = 1	

	EXEC NotaCredito.EliminarNotaCredito	@id = 1

-------TESTING PARA CIFRADO:

SELECT * FROM Sucursal.Empleados
EXEC Cifrado.TransferirEmpleadosCifrados	@FraseClave = 'AvenidaSiempreViva742'		--Frase clave para cifrar los datos
SELECT * FROM Sucursal.Empleados

EXEC Sucursal.AgregarEmpleado				@Nombre = 'Marcelo',
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

SELECT * FROM Sucursal.Empleados

EXEC Sucursal.ActualizarEmpleado			@Legajo = '257036',
											@Direccion = 'enrique segoviano 1944',
											@EmailPersonal = 'Bombaloca@gmail.com',
											@Cargo = 'Gerente de sucursal',
											@Sucursal = 'San Justo',
											@Turno = 'Jornada completa',
											@FraseClave = 'AvenidaSiempreViva742'
GO	

SELECT * FROM Sucursal.Empleados

DECLARE @PATH VARCHAR(255) = 'C:\Users\kerse\Desktop\TP_integrador_Archivos'
DECLARE @FullPath VARCHAR(500) = @PATH + '\Informacion_complementaria2.xlsx'

EXEC Carga.CargarEmpleados					@direccion = @FullPath,
											@FraseClave = 'AvenidaSiempreViva742'