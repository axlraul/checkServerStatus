#!/bin/bash   

OSVersion=$(cat /etc/redhat-release | awk '{print $4}' | cut -c 1)


THRESHOLD_PERCENT=5       # Umbral de alertas de FS

skipReport=0			# Controla si debe printar el reporte de escalado de CPU/RAM/SWAP
logrotateExec=0			# Controla si se ejecuto un logrotate
msg=0 				# Variable que controla si se ha printado mensaje por pantalla con instrucciones
clear

echo -e "Introduce la opcion que deseas consultar:\n" 
echo "CPU"
echo "RAM"
echo "SWAP"
echo "FS"

echo -e "\nOpcion:"

read opcion
case $opcion in

	CPU)
echo -e "\n-------Top 3 procesos que consumen CPU"
ps -eo %cpu,pid,ppid,cmd --sort=-%cpu | head -n 4
Top1Pid=$(ps -eo pid --sort=-%cpu --no-headers | head -n 1)
	;;

	RAM)
if [[ $OSVersion == 7 ]]
then
  MEMORIA=$(echo "-%mem")	#RH7/CENTOS7
else
  MEMORIA=$(echo "-rss")	#RH6/CENTOS6
fi

echo -e "\n\n-------Top 3 procesos que consumen RAM"
ps -eo %mem,pid,ppid,cmd --sort=$MEMORIA | head -n 4
Top1Pid=$(ps -eo pid --sort=$MEMORIA --no-headers | head -n 1)
	;;

	SWAP)
echo -e "\n\n-------Top 3 procesos que consumen SWAP"
echo -e "PID - CMD - SWAP"
for file in /proc/*/status ; do awk '/VmSwap|Name|Pid/{printf $2 " " $3 }END{ print ""}' $file; done | sort -k 2 -r | egrep -i "kB|MB|GB" | head -n 3  | awk '{print $2" - "$5" "$6" - "$1}'

Top1Pid=$(for file in /proc/*/status ; do awk '/VmSwap|Name|Pid/{printf $2 " " $3 }END{ print ""}' $file; done | sort -k 2 -r | egrep -i "kB|MB|GB" | head -n 1  | awk '{print $2}')


#echo $Top1Pid
#nombreProceso=$(ps -p $Top1Pid -o comm --no-headers)
#echo $nombreProceso
#nombreProcesoLargo=$(ps -p $Top1Pid -o cmd --no-headers)
#echo $nombreProcesoLargo
        ;;

	FS)
echo -e "\n\n-------Listado de FS en alerta"
skipReport=1
#set -e
if [[ $OSVersion == 7 ]]
then
  dfCommand=$(df --output=pcent,target)
else
  df -P | awk '{print $5"  "$6}'| head -n 1
  dfCommand=$(df -P | awk '{print $5"        "$6}' | grep -v Capacity)
fi
  echo "$dfCommand" | while read line
do
  list_logrotate_installed=$(cat /etc/logrotate.d/* | egrep -v "{|}|  |HUP |null|>|<|#" | sed '/^[[:space:]]*$/d')
  if [[ "$line" != Use* ]] && [[ ! -z "$line" ]]  && [[ "$line" != '' ]]
  then
    percent=${line/\%*/};
    if (( percent >= THRESHOLD_PERCENT ))
    then
      file=${line/* /}
      echo -e "%Ocupado Filesystem"
      echo -e "$percent% \t $file"
      if grep -q "$file" <<< "$list_logrotate_installed"
      then
        get_logrotate_name=$(grep ${file} /etc/logrotate.d/* | cut -d: -f1)
        echo -e "Liberando espacio - logrotate $get_logrotate_name. Revisar en 5 minutos si la alerta se ha resuelto \n"
        logrotate -f $get_logrotate_name
      else
        echo -e "No se ha podido liberar espacio automaticamente en $file\n"
      fi
    fi
  fi
done
	;;
	*)
	echo -e "Opcion no correcta, vuelve a intentarlo\n\n"
	;;
esac

if [[ $skipReport == 0 ]]
then
  #echo $Top1Pid
  nombreProceso=$(ps -p $Top1Pid -o comm --no-headers)
  #echo $nombreProceso
  nombreProcesoLargo=$(ps -p $Top1Pid -o cmd --no-headers)
  #echo $nombreProcesoLargo
  source ./escalation.txt
  sistema=$(echo $HOSTNAME | cut -b 1,2,3,4,5)

  while read line; 
  do
    listProceso=$(echo $line | awk -F'|' '{print $2}' | egrep -w "$nombreProceso|ALL")
    listSistema=$(echo $line | awk -F'|' '{print $1}' | egrep -w "$sistema|ALL")
    if [[ ! -z $listProceso ]]
    then
      if [[ ! -z $listSistema && $listSistema == $sistema && $listProceso == $nombreProceso || ! -z $listSistema && $listSistema == "ALL" && $listProceso == $nombreProceso ]]
      then
        echo -e "\n\nLa alerta de $opcion detectada debe tratarse de la siguiente manera:\n"
        eval echo $(echo $line | awk -F'|' '{print $3}')
        echo "info a reportar:"
        echo "Pid: $Top1Pid"
        echo "Proceso: $nombreProcesoLargo"
        echo "Capturar toda la información mostrada y adjuntarla en el correo informativo a enviar"
        echo -e "\n"
        msg=1
      fi
    fi
  done < list.txt
  if [[ $msg == 0 ]]
  then
    echo -e "\nAlerta no identificada. La alerta debe ser escalada a SSMM-MF. Es necesario tambien enviar un correo adjuntando la informacion mostrada anteriormente \n"
  fi
fi
