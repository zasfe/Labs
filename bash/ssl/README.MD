openssl tls cipher suites check
======

testssl.sh
-----------


```
$docker run --rm -ti  drwetter/testssl.sh <your_cmd_line>
```



SSLyze
-----------

On Windows, Linux (x86 or x64) and macOS, SSLyze can be installed directly via pip:

```
$ pip install --upgrade pip setuptools wheel
$ pip install --upgrade sslyze
$ python -m sslyze www.yahoo.com www.google.com "[2607:f8b0:400a:807::2004]:443"
```

It can also be used via Docker:

```
$ docker run --rm -it nablac0d3/sslyze:6.0.0 www.google.com
```

enum-ciphersuite.sh
-----------

```
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

# ./enum-ciphersuite.sh www.hahwul.com:443
# Enum cipher list from LibreSSL 2.8.3.
# ========================
# ECDHE-RSA-AES256-GCM-SHA384
# ECDHE-RSA-AES256-SHA384
# ECDHE-RSA-AES256-SHA
# ...
```
