# checkServerStatus
Revision de un servidor Linux a nivel de CPU/RAM/SWAP y ejecucion auto de logrotate en FS

Funcionamiento:

sh checkServerStatus.sh
Seleccionar CPU/RAM/SWAP/FS

- CPU/RAM/SWAP identifican que proceso esta causando la alerta detectada y proporciona instrucciones a realizar.
- FS identifica el FS que estan en alerta, detecta si existe logrotate e intenta ejecutarlos.


Para configurar las instrucciones, deben editarse los siguientes archivos:


- list.txt
Se define la siguiente información: 
SISTEMA(5 letras maximo)|proceso|Escalado
Ejemplo:

ALL|dsmc|$Backup 
#Aplica a todos los hostnames donde se instale el script independientemente del sistema al que pertenezcan
sist1|BESClient|$AgenteBasico
#Aplica al sistema llamado sist1, al proceso BESClient y cuyas instrucciones estaran definidas en la variable $AgenteBasico del documento escalation.txt


- escalation.txt
Se definen las instrucciones asociadas a escalados predefinidos. Cuando el script checkServerStatus.sh se ejecuta y la consulta realizada de CPU/RAM/SWAP y detecta que existe coincidencia en una linea definida en list.txt en que el proceso que más CPU/RAM/SWAP y el nombre del sistema, se dara el mensaje definido. Por ejemplo, siguiendo el ejemplo:

$Aplicativo=$(echo "Escalar a equipo aplicativo")

Variables a configurar:

THRESHOLD_PERCENT=75           # Umbral de FS a partir el cual se intentará ejecutar el logrotate, en %

