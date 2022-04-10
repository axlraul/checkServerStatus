#!/bin/bash   

THRESHOLD_PERCENT=10            #Umbral de alertas de FS

host=`hostname -f`
echo "$host"

#/proc/meminfo
clear

echo -e "\n-------Top 3 procesos que consumen CPU"
ps -eo %cpu,ppid,cmd --sort=-%cpu | head -n 4



echo -e "\n\n-------Top 3 procesos que consumen RAM"

#for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -r | egrep -i "kB|MB|GB" | head -n 5


ps -eo %mem,pid,ppid,cmd --sort=-%mem | head -n 4




echo -e "\n\n-------Top 3 procesos que consumen SWAP"

echo -e "CMD - SWAP"
for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -r | egrep -i "kB|MB|GB" | head -n 3

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
done



