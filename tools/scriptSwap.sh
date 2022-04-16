stress --vm-bytes $(awk '/MemFree/{printf "%d\n", $2 * 0.111;}' < /proc/meminfo)k --vm-keep -m 10
