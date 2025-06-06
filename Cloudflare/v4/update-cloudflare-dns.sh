#!/usr/bin/env bash

###  Create .update-cloudflare-dns.log file of the last run for debug
parent_path="$(dirname "${BASH_SOURCE[0]}")"
FILE=${parent_path}/update-cloudflare-dns.log
if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

LOG_FILE=${parent_path}'/update-cloudflare-dns.log'

### Write last run of STDOUT & STDERR as log file and prints to screen
exec > >(tee $LOG_FILE) 2>&1
echo "==> $(date "+%Y-%m-%d %H:%M:%S")"

### Validate if config file exists

if [[ -z "$1" ]]; then
  if ! source ${parent_path}/update-cloudflare-dns.conf; then
    echo 'Error! Missing configuration file update-cloudflare-dns.conf or invalid syntax!'
    exit 0
  fi
else
  if ! source ${parent_path}/"$1"; then
    echo 'Error! Missing configuration file '$1' or invalid syntax!'
    exit 0
  fi
fi

### Check validity of "ttl" parameter
if [ "${ttl}" -lt 120 ] || [ "${ttl}" -gt 7200 ] && [ "${ttl}" -ne 1 ]; then
  echo "Error! ttl out of range (120-7200) or not set to 1"
  exit
fi

### Check validity of "proxied" parameter
if [ "${proxied}" != "false" ] && [ "${proxied}" != "true" ]; then
  echo 'Error! Incorrect "proxied" parameter choose "true" or "false"'
  exit 0
fi

### Check validity of "what_ip" parameter
if [ "${what_ip}" != "external" ] && [ "${what_ip}" != "internal" ] && [ "${what_ip}" != "api_ec2" ]; then
  echo 'Error! Incorrect "what_ip" parameter choose "external" or "internal" or "api_ec2"'
  exit 0
fi

### Check if set to internal ip and proxy
if [ "${what_ip}" == "internal" ] && [ "${proxied}" == "true" ]; then
  echo 'Error! Internal IP cannot be Proxied'
  exit 0
fi

### Check if set to api_ec2 and instance id
if [ "${what_ip}" == "api_ec2" ] && [ "${aws_instance_ids}" == "" ]; then
  echo 'Error! Missing configuration aws ec2 Instance id'
  exit 0
fi


### Get API ip from aws cli
if [ "${what_ip}" == "api_ec2" ]; then
  ip=$(aws ec2 describe-instances --instance-ids ${aws_instance_ids} --query "Reservations[*].Instances[*].PublicIpAddress" | egrep -v "\[|\]" | awk -F \" '{print$2}')
  if [ -z "$ip" ]; then
    echo "Error! Can't get ec2 ip from aws cli"
    exit 0
  fi
  echo "==> AWS EC2 External IP is: $ip"
fi



### Get External ip from https://checkip.amazonaws.com
if [ "${what_ip}" == "external" ] && [ "${what_ip}" != "api_ec2" ]; then
  ip=$(curl --insecure -4 -s -X GET https://checkip.amazonaws.com --max-time 10)
  if [ -z "$ip" ]; then
    echo "Error! Can't get external ip from https://checkip.amazonaws.com"
    exit 0
  fi
  echo "==> External IP is: $ip"
fi

### Get Internal ip from primary interface
if [ "${what_ip}" == "internal" ]; then
  ### Check if "IP" command is present, get the ip from interface
  if which ip >/dev/null; then
    ### "ip route get" (linux)
    interface=$(ip route get 1.1.1.1 | awk '/dev/ { print $5 }')
    ip=$(ip -o -4 addr show ${interface} scope global | awk '{print $4;}' | cut -d/ -f 1)
  ### if no "IP" command use "ifconfig", get the ip from interface
  else
    ### "route get" (macOS, Freebsd)
    interface=$(route get 1.1.1.1 | awk '/interface:/ { print $2 }')
    ip=$(ifconfig ${interface} | grep 'inet ' | awk '{print $2}')
  fi
  if [ -z "$ip" ]; then
    echo "Error! Can't read ip from ${interface}"
    exit 0
  fi
  echo "==> Internal ${interface} IP is: $ip"
fi

dns_server1="1.1.1.1"
dns_server2=$(cat /etc/resolv.conf | grep -v "#" | grep -i nameserver | head -n 1 | awk '{print$2}')
### Build coma separated array fron dns_record parameter to update multiple A records
IFS=',' read -d '' -ra dns_records <<<"$dns_record,"
unset 'dns_records[${#dns_records[@]}-1]'
declare dns_records

for record in "${dns_records[@]}"; do
  ### Get IP address of DNS record from 1.1.1.1 DNS server when proxied is "false"
  if [ "${proxied}" == "false" ]; then
    ### Check if "nsloopup" command is present
    if which nslookup >/dev/null; then
      dns_record_ip=$(nslookup ${record} ${dns_server1} | awk '/Address/ { print $2 }' | sed -n '2p')
    else
      ### if no "nslookup" command use "host" command
      dns_record_ip=$(host -t A ${record} ${dns_server1} | awk '/has address/ { print $4 }' | sed -n '1p')
    fi

    if [ -z "$dns_record_ip" ]; then
      echo "Error! Can't resolve the ${record} via ${dns_server1} DNS server"
      echo "Try resolve the ${record} via ${dns_server2} DNS server by /etc/resolv.conf"
      ### Check if "nsloopup" command is present
      if which nslookup >/dev/null; then
        dns_record_ip=$(nslookup ${record} ${dns_server2} | awk '/Address/ { print $2 }' | sed -n '2p')
      else
        ### if no "nslookup" command use "host" command
        dns_record_ip=$(host -t A ${record} ${dns_server2} | awk '/has address/ { print $4 }' | sed -n '1p')
      fi

      if [ -z "$dns_record_ip" ]; then
        echo "Error! Can't resolve the ${record} via ${dns_server2} DNS server"
      fi
    fi


    if [ -z "$dns_record_ip" ]; then
      echo "Error! Can't resolve the ${record} via ALL DNS server"
      exit 0
    fi

    is_proxed="${proxied}"
  fi

  ### Get the dns record id and current proxy status from cloudflare's api when proxied is "true"
  if [ "${proxied}" == "true" ]; then
    dns_record_info=$(curl --insecure -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$record" \
      -H "Authorization: Bearer $cloudflare_zone_api_token" \
      -H "Content-Type: application/json")
    if [[ ${dns_record_info} == *"\"success\":false"* ]]; then
      echo ${dns_record_info}
      echo "Error! Can't get dns record info from cloudflare's api"
      exit 0
    fi
    is_proxed=$(echo ${dns_record_info} | grep -o '"proxied":[^,]*' | grep -o '[^:]*$')
    dns_record_ip=$(echo ${dns_record_info} | grep -o '"content":"[^"]*' | cut -d'"' -f 4)
  fi

  ### Check if ip or proxy have changed
  if [ ${dns_record_ip} == ${ip} ] && [ ${is_proxed} == ${proxied} ]; then
    echo "==> DNS record IP of ${record} is ${dns_record_ip}", no changes needed.
    continue
  fi

  echo "==> DNS record of ${record} is: ${dns_record_ip}. Trying to update..."

  ### Get the dns record information from cloudflare's api
  cloudflare_record_info=$(curl --insecure -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$record" \
    -H "Authorization: Bearer $cloudflare_zone_api_token" \
    -H "Content-Type: application/json")
  if [[ ${cloudflare_record_info} == *"\"success\":false"* ]]; then
    echo ${cloudflare_record_info}
    echo "Error! Can't get ${record} record inforamiton from cloudflare API"
    exit 0
  fi

  ### Get the dns record id from response
  cloudflare_dns_record_id=$(echo ${cloudflare_record_info} | grep -o '"id":"[^"]*' | cut -d'"' -f4)

  ### Push new dns record information to cloudflare's api

  record_cmt="$(date "+%Y-%m-%d %H:%M") - ${dns_record_ip} => ${ip}"

  update_dns_record=$(curl --insecure -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$cloudflare_dns_record_id" \
    -H "Authorization: Bearer $cloudflare_zone_api_token" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$record\",\"content\":\"$ip\",\"ttl\":$ttl,\"proxied\":$proxied,\"comment\":\"${record_cmt}\"}")
  if [[ ${update_dns_record} == *"\"success\":false"* ]]; then
    echo ${update_dns_record}
    echo "Error! Update Failed"
    exit 0
  fi



  echo "==> Success!"
  echo "==> $record DNS Record Updated To: $ip, ttl: $ttl, proxied: $proxied"

  ### Telegram notification
  if [ ${notify_me_telegram} == "no" ]; then
    exit 0
  fi

  if [ ${notify_me_telegram} == "yes" ]; then
    telegram_notification=$(
      curl --insecure -s -X GET "https://api.telegram.org/bot${telegram_bot_API_Token}/sendMessage?chat_id=${telegram_chat_id}" --data-urlencode "text=${record} DNS record updated to: ${ip}"
    )
    if [[ ${telegram_notification=} == *"\"ok\":false"* ]]; then
      echo ${telegram_notification=}
      echo "Error! Telegram notification failed"
      exit 0
    fi
  fi
done
