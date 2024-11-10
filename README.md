# TP INTEGRADOR BASE DE DATOS

## OPCIONES PARA DESCARGAR EL PROYECTO
### GIT
***Se debe tener instalado GIT (https://git-scm.com/downloads)***
- Se clona el repositorio de Github en el directorio deseado de la computadora
```git clone https://github.com/maganor/TPBDA.git ```
### FORMA MANUAL
Se descarga un .zip directo desde la pagina de GitHub.
- Click en la pestania verde, arriba de los archivos, y la ultima opcion que dice Descargar ZIP
## SISTEMA UTILIZADO
- CPU: 4 Cores
- Memoria Ram: 8GB
- Espacio utilizado por el proyecto < 100 MB
## SQL SERVER/SMSS
- Media Location: C:\SQL2022
- NO utilizar Azure Extension for SQL Server
---
- Instance Features utilizadas:
    - Database Engine Services
        - Ninguna de las opciones
- Instance Root Directory: C:\Program Files\Microsoft SQL Server\
- Shared Feature Directory: C:\Program Files\Microsoft SQL Server\
- Shared Feature Directory: C:\Program Files(x86)\Microsoft SQL Server\
---
- Named instance con el nombre COM5600G01
- SQL Server Directory:  C:\Program Files\Microsoft SQL Server\MSSQL16.COM5600G01
---
- Service Accounts
    - SQL Server Database Engine: NT SERVICE\MSSQL$COM5600G01 - Automatic
- Collation: SQL_Latin1_General_CP1_CI_AS
---
- Server Configuration
    - Mixed Mode (Cuenta: sa - Pass = COM5600G01)
    - Administrators: Mauri\Mauri (mauri)
- Data Directories
    - Data root directory: C:\Program Files\Microsoft SQL Server\
    - User database directory: C:\Program Files\Microsoft SQL Server\MSSQL16.COM5600G01\Data
    - User database log directory: C:\Program Files\Microsoft SQL Server\MSSQL16.COM5600G01\Data
    - Backup directory: C:\Program Files\Microsoft SQL Server\MSSQL16.COM5600G01\Backup
- TempDB
    - 1 solo archivo, con un tamaño inicial de 8MB y un autogrowth de 32MB
    - Data Directories: Solo C:\Program Files\Microsoft SQL Server\MSSQL16.COM5600G01\Data
    - El TempDB log, tiene los mismo tamaño que la tempDB, y el log directory tambien igual a ese unico
- Memory
    - Recommended
    - Marcar la opcion de aceptar las configuraciones recomendadas tambien
- User instances
    - Permitido
- FILESTREAM
    - Deshabilitado
---

## Utilizacion de la base de datos
- Se abre el archivo TPDBA.ssmsln, ubicado en la carpeta principal del proyecto.
- La ejecucion de los archivos se debe ir haciendo acorde al numero que tienen.
- Al momento de la carga de los datasets se tiene que modificar la variable @PATH, con la ubicacion respectiva, asegurarse que el servicio de la base de datos tenga los permisos necesarios para acceder a ellos.

## Politicas de Backup
**Replicación de tabla Facturas y procedimientos de reportes XML**: 
Dado que la información de ventas diarias es fundamental, se establece una réplica de la tabla Facturas y de los procedimientos almacenados que generan los reportes XML. Esta replicación no solo asegura disponibilidad ante fallos de hardware o corrupción de datos, sino que permite un acceso continuo a los datos críticos sin implementar una infraestructura de alta disponibilidad en toda la base de datos.

**Backup completo semanal**:
Cada domingo al finalizar los turnos para generar un respaldo completo de los datos al cierre de cada semana, manteniendo la consistencia y reduciendo el tiempo de restauración en caso de un fallo mayor. En dicho momento suelen generarse menos movimientos, lo que ayudaría en la asignación de recursos para la generación del respaldo completo.

**Backup diferencial diario**:
Cada día al finalizar los turnos para optimizar y agilizar el tiempo de restauración de los respaldos y la asignación de los recursos para llevar adelante dicho respaldo.

## DER
![image](https://github.com/user-attachments/assets/7b991786-0fcb-4170-91c9-ebfc5083680c)
