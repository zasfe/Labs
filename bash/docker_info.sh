#!/bin/bash

# docker info
docker info | egrep -i "(^Server|^Docker|^Registry|^Product|^Swarm)"


