#!/bin/bash
#
# @Author: Josh Sunnex
# @Date:   2019-01-31 10:26:00
# @Last Modified by:   josh5
# @Last Modified time: 2019-01-31 10:36:07
# https://gist.github.com/Josh5/ff6ccfe4c75ae27a3f1efebcb645e7c4
# usage:
#           curl -sSL https://gist.githubusercontent.com/Josh5/ff6ccfe4c75ae27a3f1efebcb645e7c4/raw/calculate_apache_mpm_config.sh | bash -s [PID]
#
# Replace '[PID]' with the PID of the parent apache process

if [[ ! ${1} ]]; then
    echo "Need to supply a PID";
    echo 
    echo "USAGE: curl -sSL https://gist.githubusercontent.com/Josh5/ff6ccfe4c75ae27a3f1efebcb645e7c4/raw/calculate_apache_mpm_config.sh | bash -s [PID]"
    echo 
    echo 
    exit 1
fi

MAX_PROCESS_RAM=${MAX_PROCESS_RAM:-400}
echo
echo "Working off a max process RAM (MAX_PROCESS_RAM) of ${MAX_PROCESS_RAM}";
echo "Change this figure to suit your needs";
echo


# System info:
echo
echo
CPU_CORES=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l);
MEMORY_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}' | awk '{ byte =$1 /1024; print byte "" }');
echo "Number of CPU Cores available:    ${CPU_CORES}";
echo
echo "Total RAM available:              ${MEMORY_TOTAL}MB";
echo

function getMemoryUse {
    echo "$(ps u -p ${1} | awk '{sum=sum+$6}; END {print sum/1024}')";
}



PID=${1};
CHILD_PIDS='';
TOTAL_MEMRY_USED=0;

getChildrePids() {
    CHILD_PID=$(pgrep -P ${1});
    CHILD_PIDS="${CHILD_PIDS} ${CHILD_PID}";
    if [[ ! -z ${CHILD_PID} ]]; then
        getChildrePids ${CHILD_PID};
    fi
}

getChildrePids ${PID};

PARENT_PROCESS_NAME=$(ps -p ${PID} -o comm=);
PARENT_MEMORY_USE=$(getMemoryUse ${PID});
ROUNDED_PARENT_MEMORY_USE=$(printf '%.*f\n' 2 ${PARENT_MEMORY_USE});
TOTAL_MEMRY_USED=$(echo | awk "{ print ${TOTAL_MEMRY_USED} + ${PARENT_MEMORY_USE} }");

echo "Main Process:          ${ROUNDED_PARENT_MEMORY_USE}MB  - ${PARENT_PROCESS_NAME}";
for CHILD in ${CHILD_PIDS}; do
    PROCESS_NAME=$(ps -p ${CHILD} -o comm=);
    MEMORY_USE=$(getMemoryUse ${CHILD});
    ROUNDED_MEMORY_USE=$(printf '%.*f\n' 2 ${MEMORY_USE});
    TOTAL_MEMRY_USED=$(echo | awk "{ print ${TOTAL_MEMRY_USED} + ${MEMORY_USE} }")
    echo "   - Child process:    ${ROUNDED_MEMORY_USE}MB  - ${PROCESS_NAME}";
done
ROUNDED_TOTAL_MEMRY_USED=$(printf '%.*f\n' 2 ${TOTAL_MEMRY_USED});
echo "_____________________________________________________________________________"
echo
echo "Total:                 ${ROUNDED_TOTAL_MEMRY_USED}MB";
echo
echo
echo


# Calculate 
TOTAL_RAM=${MEMORY_TOTAL}
RAM_NEEDED_BY_HOST=700
echo "MaxRequestWorkers:"
echo "((TOTAL_RAM - RAM_NEEDED_BY_HOST) / MAX_PROCESS_RAM)";

MAX_REQ_WORKERS=$(echo | awk "{ print (${TOTAL_RAM} - ${RAM_NEEDED_BY_HOST}) / ${MAX_PROCESS_RAM} }")
echo "    ((${TOTAL_RAM} - ${RAM_NEEDED_BY_HOST}) / ${MAX_PROCESS_RAM}) = ${MAX_REQ_WORKERS}";

SERVER_LIMIT_THREADS=$(echo | awk "{ print (${MAX_REQ_WORKERS} + 1) }")
ROUNDED_SERVER_LIMIT_THREADS=$(printf '%.*f\n' 0 ${SERVER_LIMIT_THREADS});
ROUNDED_SERVER_LIMIT_WORKERS=$(echo | awk "{ print (${ROUNDED_SERVER_LIMIT_THREADS} * 2) }")

echo




echo """
Below is the best option for your server:
Note:
    The MaxConnectionsPerChild is optional.
    If you whish for a worker process to last forever, then set this to '0'
<IfModule mpm_*_module>
    StartServers                ${CPU_CORES}    #(Optional)
    MinSpareThreads             25
    MaxSpareThreads             75
    ThreadLimit                 64
    ThreadsPerChild             ${ROUNDED_SERVER_LIMIT_THREADS}
    MaxRequestWorkers           ${ROUNDED_SERVER_LIMIT_WORKERS}
    MaxConnectionsPerChild      30              #(Optional - Less for more buggy processes to manage memory leaks)
</IfModule>
"""

echo
