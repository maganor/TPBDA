# TPDBA
TP Base de Datos Aplicada

> [!IMPORTANT]
> LOS QUEREMOS JAIR Y JULIO ^^

# TP INTEGRADOR BASE DE DATOS

## REQUISITOS TECNICOS
**SISTEMA OPERATIVO RECOMENDADO** : Windows Server 2022
**CPU**: Se necesita que tenga 4 cores como minimo. Se recomienda tener 8.
**MEMORIA RAM**: Con 16GB esta bien, en este momento, pero se podria necesitar mas a corto plazo.
**DISCO DURO**: 100GB.


## OPCIONES PARA DESCARGAR EL PROYECTO
### GIT
***Se debe tener instalado GIT (https://git-scm.com/downloads)***
- Se clona el repositorio de Github en el directorio deseado de la computadora
```git clone https://github.com/maganor/TPBDA.git ```
### FORMA MANUAL
Se descarga un .zip directo desde la pagina de GitHub.
- Click en la pestania verde, arriba de los archivos, y la ultima opcion que dice Descargar ZIP
## SQL SERVER/SMSS
- Se instala SQL SERVER 2022 (https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
    - Al momento de instalar, realizar la instalacion custom.
    - Instalar en la ubicacion que le parezca bien.
    - No marcar la instalacion de las extensiones de azure.
    - El nombre de instancia se recomienda Aurora(Nombre Supermercado).
    - Se utiliza mixed authentication (Acordarse la contrasenia!!).
- Se instala SQL Server Management Studio (https://aka.ms/ssmsfullsetup).

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

![image](https://github.com/user-attachments/assets/59d07f85-5771-4b21-8743-2b0351eca705)


