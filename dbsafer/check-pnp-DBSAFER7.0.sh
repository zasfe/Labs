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
}

# [4] Service Status Check
check_service_status() {
  echo
  print_bright_white "== Service Status Check =="
  cd /dbsafer || { print_red "Failed to enter /dbsafer directory"; return 1; }

  ./pnp_agent service-list > _service_status.txt
  error_count=$(grep -ci error _service_status.txt)

  if [ "$error_count" -eq 1 ]; then
    print_green ">> No 'Error' found in service status."
  else
    print_red ">> $error_count service(s) show 'Error' status! Please check _service_status.txt."
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

  echo
  print_green ">> For detailed dynamic port allocation, check './pnp_agent service-list' output in /dbsafer directory."
}

# Main execution
check_essential_processes
check_service_status
check_service_processes

echo
print_green "All checks are completed."
