#!/bin/bash

set -x

docker rm $(docker stop $(docker ps -q -f "name=el7-build-server"))
docker rm $(docker stop $(docker ps -q -f "name=el6-build-server"))
