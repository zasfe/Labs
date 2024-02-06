#!/bin/bash

# Docker Swarm node check
docker node ls

# Docker Swarm network create
docker network create -d overlay --attachable ngrinder-nw

# ngrinder container run
docker run -d --restart=unless-stopped -v ~/ngrinder-controller:/opt/ngrinder-controller --name controller -p 8000:80 --network ngrinder-nw ngrinder/controller


# ngrinder agent
docker service rm agent
docker service create --name agent --network ngrinder-nw --replicas 4 ngrinder/agent 

# ngrinter manager node drain
# docker node update --availability drain NODENAME


# docker service scale agent=12



## nGrinder Uninstall
# docker service rm agent
# docker stop controller
# docker rm controller
# docker rmi controller agent




