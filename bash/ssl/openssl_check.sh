#!/bin/bash

openssl s_client -connect 127.0.0.1:443 -servername zasfe.com
openssl s_client -connect 127.0.0.1:443 -servername zasfe.com 2>/dev/null | openssl x509 -noout -dates
