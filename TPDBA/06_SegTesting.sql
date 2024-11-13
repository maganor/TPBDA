USE Com5600G01	

SELECT * FROM Complementario.Empleados
EXEC Procedimientos.TransferirEmpleadosCifrados @FraseClave = 'AvenidaSiempreViva742'		--Frase clave para cifrar los datos
SELECT * FROM Complementario.Empleados

EXECUTE AS USER = 'CajeroTest'
	EXEC NotaCredito.EliminarNotaCredito @id = 1
REVERT

EXECUTE AS USER = 'GerenteTest'
	EXEC NotaCredito.EliminarNotaCredito @id = 1
REVERT
