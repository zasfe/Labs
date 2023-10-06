#!/bin/bash

# Load Gernerator
# CPU(Core): 1
# Memory: 90% on Total
# Time(s): 500

sudo stress --cpu 1 --vm-bytes $(awk '/MemAvailable/{printf "%d\n", $2 * 0.9;}' < /proc/meminfo)k --timeout 500


