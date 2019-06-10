#!/bin/bash

# Inspired from benkulbertis/cloudflare-update-record.sh and lifehome/cfupdater

# Cloudflare API
auth_email="email"            # Your cloudflare account email.
auth_key="globalapi"          # Your cloudflare global api.
zone_name="domain"            # Domain you want to include. E.g., example.com
record_name="record"          # Record you want to include. E.g., example.com, www.example.com
record_type="A"               # What type of record is it? E.g., IPv4 (A), IPv6 (AAAA)
proxied_value="true"          # Do you want to proxy your site through cloudflare? E.g., Orange Cloud (true), Grey Cloud (false)

# Cloudflare DDNS   
ip_file="/location/ip.txt"
id_file="/location/cloudflare.ids"
log_file="/location/cloudflare.log"

# LOGGER
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}

# SCRIPT START
echo "[CF DDNS] IP CHECK INITIATED FOR $record_name..."

# INTERNET AVAILABILITY
echo "[CF DDNS] CHECKING FOR INTERNET AVAILABILITY..."
wget -q --tries=3 --timeout=10 --spider https://www.google.com > /dev/null

if [[ $? -eq 0 ]]; then
    echo "[CF DDNS] INTERNET IS AVAILABLE!"
else
    echo "[CF DDNS] INTERNET IS UNAVAILABLE!"
    echo "[CF DDNS] EXITING..."
    exit
fi

# SAVED IP
sav_ip=$(cat $ip_file)
echo "[CF DDNS] SAVED IP: $sav_ip"

# CURRENT IP
echo "[CF DDNS] CHECKING FOR NEW IP..."
# FOR IPV6 EDIT THE LINK TO THIS -> (https://api6.ipify.org)
cur_ip=$(curl -s -m 10 https://api.ipify.org) > /dev/null

if [ -f $ip_file ]; then
    pre_ip=$sav_ip
    if [ "$cur_ip" == "$pre_ip" ]; then
        echo "[CF DDNS] NO NEW IP DETECTED!"
        echo "[CF DDNS] EXITING..."
        exit 0
    fi
fi

# RETRIEVE/ SAVE zone_id AND record_id
if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    zone_id=$(head -1 $id_file)
    record_id=$(tail -1 $id_file)
else
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    record_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=$record_type&name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
    echo "$zone_id" > $id_file
    echo "$record_id" >> $id_file
fi

# UPDATE RECORD
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_id\",\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$cur_ip\",\"proxied\":$proxied_value}")

if [[ $update == *"\"success\":false"* ]]; then
    # ERROR
    message="[CF DDNS] IP UPDATE FAILED! DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    echo "[CF DDNS] EXITING..."
    exit 1
else
    # NEW IP
    echo "[CF DDNS] NEW IP DETECTED!"
    message="[CF DDNS] IP UPDATED TO: $cur_ip"
    echo "$cur_ip" > $ip_file
    log "$message"
    echo "$message"
    echo "[CF DDNS] EXITING..."
fi
