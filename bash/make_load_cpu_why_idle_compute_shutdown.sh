#!/bin/bash

# Load Gernerator
# CPU(Core): 1
# Memory: 90% on Total
# Time(s): 500

# sudo stress --cpu 1 --vm-bytes $(awk '/MemAvailable/{printf "%d\n", $2 * 0.9;}' < /proc/meminfo)k --timeout 500
sudo nohup stress --cpu 2 --vm-bytes $(awk '/MemAvailable/{printf "%d\n", $2 * 0.1;}' < /proc/meminfo)k >/dev/null 2>&1 &


# [ CentOS ]
# sudo yum -y install epel-release; 
# sudo yum -y install stress;
# wget https://raw.githubusercontent.com/zasfe/Labs/master/bash/load_cpu_why_idle_compute_shutdown.sh
# chmod +x ./load_cpu_why_idle_compute_shutdown.sh

# [ Ubuntu ]
# sudo apt-get install -y stress
# wget https://raw.githubusercontent.com/zasfe/Labs/master/bash/load_cpu_why_idle_compute_shutdown.sh
# chmod +x ./load_cpu_why_idle_compute_shutdown.sh

