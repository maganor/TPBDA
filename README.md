# TP INTEGRADOR BASE DE DATOS

## OPCIONES PARA DESCARGAR EL PROYECTO
### GIT
***Se debe tener instalado GIT (https://git-scm.com/downloads)***
- Se clona el repositorio de Github en el directorio deseado de la computadora
```git clone https://github.com/maganor/TPBDA.git ```
### FORMA MANUAL
Se descarga un .zip directo desde la pagina de GitHub.
- Click en la pestaña verde, arriba de los archivos, y la ultima opcion que dice Descargar ZIP
## SISTEMA UTILIZADO
- S.O.: Windows 11 Home
- CPU: Processor: AMD Ryzen 5 5500U, 2100 Mhz, 6 Cores 12 Threads
- Memoria Ram: 8GB
- Espacio utilizado por el proyecto < 500 MB
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
- Instancia con el nombre COM5600G01
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
    - 1 solo archivo, con un tamaño inicial de 8MB y un autogrowth de 16MB
    - Data Directories: Solo C:\Program Files\Microsoft SQL Server\MSSQL16.COM5600G01\Data
    - El TempDB log, tiene los mismo tamaño que la tempDB, y el log directory tambien igual a ese unico
- Memoria
    - MIN 500MB - MAX 4GB
- FILESTREAM
    - Deshabilitado
---

## Utilizacion de la base de datos
- Se abre el archivo TPDBA.ssmsln, ubicado en la carpeta principal del proyecto.
- La ejecucion de los archivos se debe ir haciendo acorde al numero que tienen.
- Al momento de la carga de los datasets se tiene que modificar la variable @PATH, con la ubicacion respectiva, asegurarse que el servicio de la base de datos tenga los permisos necesarios para acceder a ellos.

## Politicas de Backup
**Backup Completo Semanal**:
Cada domingo al finalizar el último turno para generar un respaldo completo de los datos al cierre de cada semana, por lo tanto, se mantendría la consistencia de datos y se reduciría el tiempo de restauración en caso de un fallo mayor y no se cuenta con un respaldo tan reciente. Además, en ese horario elegido suelen generarse menos movimientos o ninguno, dado que es el momento de cierre del negocio, lo que ayudaría cuando se tienen que asignar los recursos para generar el respaldo completo, dado que solo se destinarían para dicha acción que al ser un backup full tiene un costo mayor en cuanto a recursos, tiempo y espacio a comparación de otros dado que se guarda toda la base de datos por completo.

**Backup Diferencial Diario**:
Cada día al finalizar los turnos para optimizar y agilizar el tiempo de restauración de los respaldos y la asignación de los recursos para llevar adelante dicho respaldo. Al igual que el caso anterior, la elección del horario es por la misma razón, se realizan pocos o ningún movimiento por lo tanto agiliza el proceso y, como ya se contaría con un backup full al comenzar la semana, solo se guarda la diferencia por día que a su vez se la asume también como base para el respaldo del siguiente día, ahorrándose así tiempo y espacio de almacenamiento.

**Backup del Log de Transacciones**:
Todos los días a cada hora, dado que es el menos costoso en tiempo y espacio comparado con los anteriores, se podría realizar a cada hora un respaldo del log de transacciones para guardar los movimientos y cambios que se van generando en la base de datos a cada hora para que, en caso de tener que volver atrás por alguna falla, se pueda retornar lo más actual posible gracias al uso del último backup full, diferencial y dicho respaldo del log.

**Adicional: Replicación de tablas Facturas y DetalleVentas**: 
Dado que la información de ventas diarias es fundamental, en caso de ser necesario y a modo de mayor protección, además se podría establecer una política de restauración a través de las réplicas de las tablas "Facturas" y "DetalleVentas". Esto aseguraría la disponibilidad y acceso a ambas tablas que son vitales para el negocio ante fallos de hardware o perdida de datos.

## DER
![image](https://github.com/user-attachments/assets/3516c202-5b2e-4eaa-a379-440e093d44ef)



