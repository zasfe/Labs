#!/usr/bin/env bash
#
# vim:ts=5:sw=5:expandtab

SERVER=$1
DELAY=1
ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

echo Enum cipher list from $(openssl version).
echo "========================"

for cipher in ${ciphers[@]}
do
result=$(echo -n | openssl s_client -cipher "$cipher" -connect $SERVER 2>&1)
if [[ "$result" =~ ":error:" ]] ; then
    a=1
else
  if [[ "$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher    :" ]] ; then
    echo ${cipher}
  fi
fi
sleep $DELAY
done
