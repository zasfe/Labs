#!/bin/bash

# ANSI color codes
COLOR_RESET="\e[0m"
COLOR_BRIGHT_WHITE="\e[1;37m"
COLOR_GREEN="\e[0;32m"
COLOR_RED="\e[0;31m"

# Print messages with color prepended
print_bright_white() {
  echo -e "${COLOR_BRIGHT_WHITE}$1${COLOR_RESET}"
}

print_green() {
  echo -e "${COLOR_GREEN}$1${COLOR_RESET}"
}

print_red() {
  echo -e "${COLOR_RED}$1${COLOR_RESET}"
}

# [3] Essential Process Check
check_essential_processes() {
  print_bright_white "== Essential PNP Processes Check =="
  essential=(
    "pnp_launcher"
    "pnp_agent"
    "pnp_oms_dms"
    "pnp_log"
    "pnp_log_bridge"
    "pnp_ntpsync"
    "pnp_backup3"
    "pnp_checkintegrity"
    "pnp_update_server"
    "pnp_sysmon"
    "pnp_msg_tunnel"
    "pnp_watcher"
  )
  
  echo " - check command : ps -ef | grep pnp | grep -v grep | grep -v drop | grep -v sshd";
  echo ""
  missing=0
  for pname in "${essential[@]}"; do
    if ps -ef | grep "$pname" | grep -v grep | grep -v drop | grep -v sshd > /dev/null; then
      print_green " - $pname: running"
    else
      print_red " - $pname: not running"
      missing=1
    fi
  done

  if [ $missing -eq 1 ]; then
    print_red ">> Some essential processes are not running. Please start services and check again:"
    echo "   sudo systemctl start mysql"
    echo "   sudo systemctl start pnp"
  else
    print_green ">> All essential processes are running."
  fi
  echo ""
}

# [4] Service Status Check
check_service_status() {
  echo
  print_bright_white "== Service Status Check =="
  cd /dbsafer || { print_red "Failed to enter /dbsafer directory"; return 1; }

  ./pnp_agent service-list > _service_status.txt
  cat /dbsafer/_service_status.txt

  # Sum the numbers in the "Error" column (6th field, assuming table format)
  error_sum=$(awk -F'|' 'NR>3 && NF>6 {gsub(/ /,"",$6); if($6~/^[0-9]+$/) s+=$6} END{print s+0}' _service_status.txt)

  if [ "$error_sum" -gt 0 ]; then
    print_red ">> Total Error count in service status is $error_sum! Please check _service_status.txt."
  else
    print_green ">> No error(s) found in service status."
  fi

  if grep -i dynamic _service_status.txt > /dev/null; then
    print_green ">> Some listen port information is marked as 'Dynamic'."
  fi
}

# [5] Service Process Check (dbms related processes)
check_service_processes() {
  echo
  print_bright_white "== Service Process Check (DBMS related) =="

  dbms_procs=$(ps -ef | grep pnp | grep dbms | grep -v grep)
  if [ -n "$dbms_procs" ]; then
    echo "$dbms_procs"
    print_green ">> DBMS-related module processes are running (dynamic port allocation)."
  else
    print_red ">> No DBMS-related module processes found!"
  fi
}

# Main execution
check_essential_processes
check_service_status
check_service_processes

echo
echo "All checks are completed."
