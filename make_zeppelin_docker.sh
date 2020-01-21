#!/bin/bash

docker pull ubuntu:16.04
docker run -d --name zeppelin ubuntu:16.04 /bin/bash -c "ping 127.0.0.1 >null"
