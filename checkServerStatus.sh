#!/bin/bash   

THRESHOLD_PERCENT=10            #Umbral de alertas de FS

host=`hostname -f`
echo "$host"
skipReport=0
#/proc/meminfo
clear

echo -e "Introduce la opcion que deseas consultar:\n" 
echo "CPU"
echo "RAM"
echo "SWAP"
echo "FS"

read opcion
case $opcion in
	CPU)

echo -e "\n-------Top 3 procesos que consumen CPU"
ps -eo %cpu,ppid,cmd --sort=-%cpu | head -n 4
Top1Pid=$(ps -eo pid --sort=-%cpu --no-headers | head -n 1)
	;;

	RAM)
echo -e "\n\n-------Top 3 procesos que consumen RAM"
ps -eo %mem,pid,ppid,cmd --sort=-%mem | head -n 4
Top1Pid=$(ps -eo pid --sort=-%mem --no-headers | head -n 1)
	;;

	SWAP)
echo -e "\n\n-------Top 3 procesos que consumen SWAP"
echo -e "PID - CMD - SWAP"
for file in /proc/*/status ; do awk '/VmSwap|Name|Pid/{printf $2 " " $3 }END{ print ""}' $file; done | sort -k 2 -r | egrep -i "kB|MB|GB" | head -n 3  | awk '{print $2" - "$5" "$6" - "$1}'

Top1Pid=$(for file in /proc/*/status ; do awk '/VmSwap|Name|Pid/{printf $2 " " $3 }END{ print ""}' $file; done | sort -k 2 -r | head -n 1  | awk '{print $2}')

#echo $Top1Pid
#nombreProceso=$(ps -p $Top1Pid -o comm --no-headers)
#echo $nombreProceso
#nombreProcesoLargo=$(ps -p $Top1Pid -o cmd --no-headers)
#echo $nombreProcesoLargo
	;;

	FS)
echo -e "\n\n-------Listado de FS en alerta"

#set -e
df --output=pcent,target | while read line
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
        echo -e "No se ha podido liberar espacio automaticamente\n"
      fi
    fi
  fi
skipReport=1
done
	;;
	*)
	echo -e "Opcion no correcta, vuelve a intentarlo\n\n"
        skipReport=1
	;;
esac


if [[ $skipReport == 0 ]]
then
  
echo $Top1Pid
nombreProceso=$(ps -p $Top1Pid -o comm --no-headers)
echo $nombreProceso
nombreProcesoLargo=$(ps -p $Top1Pid -o cmd --no-headers)
echo $nombreProcesoLargo
source ./escalation.txt
echo "$Aplicativo"
  while read line; 
  do 
    echo $line | awk -F'|' '{print $2}' | grep -w $nombreProceso

    if [[ ! -z $(echo $line | awk -F'|' '{print $2}' | grep -w $nombreProceso) ]]
    then
      echo "el proceso debe escalarse de la siguiente manera"
#      eval $(echo $line | awk -F'|' '{print $3}')

echo "DEBE HABER PRINTADO APP"
    fi
#   echo $line; 
  done < list.txt
fi


