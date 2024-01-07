#!/bin/bash

# Load Gernerator
# CPU(Core): 1
# Memory: 90% on Total
# Time(s): 500

sudo stress --cpu 1 --vm-bytes $(awk '/MemAvailable/{printf "%d\n", $2 * 0.9;}' < /proc/meminfo)k --timeout 500


# CentOS
# sudo yum -y install epel-release; 
# sudo yum -y install stress;
# wget https://raw.githubusercontent.com/zasfe/Labs/master/bash/load_cpu_why_idle_compute_shutdown.sh
# chmod +x ./load_cpu_why_idle_compute_shutdown.sh
# echo "" >> /etc/crontab
# echo "# Load" >> /etc/crontab
# echo "0 5 * * * * opc /home/opc/load_cpu_why_idle_compute_shutdown.sh" >> /etc/crontab
# sudo systemctl restart crond

# Ubuntu
# sudo apt-get install -y stress
# wget https://raw.githubusercontent.com/zasfe/Labs/master/bash/load_cpu_why_idle_compute_shutdown.sh
# chmod +x ./load_cpu_why_idle_compute_shutdown.sh
# echo "" >> /etc/crontab
# echo "# Load" >> /etc/crontab
# echo "0 5 * * * * ubuntu /home/ubuntu/load_cpu_why_idle_compute_shutdown.sh" >> /etc/crontab
# sudo systemctl restart cron

