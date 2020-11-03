# sdwan_performance_testing

This assortment of scripts uses docker, docker-compose, docker contexts, netperf, and flent to do some automated performance testing between two devices.

More on docker contexts and how we are going to use them:
https://www.docker.com/blog/how-to-deploy-on-remote-docker-hosts-with-docker-compose/


Initial Setup

Setup Docker compose and docker engine on the server and clients manually:
To use docker contexts, you need at least compose version 1.26.0-rc2 and docker engine version XX

Docker Engine install:
https://docs.docker.com/engine/install/debian/#install-using-the-repository

Docker Compose install:
https://docs.docker.com/compose/install/

Compose on ARM:
https://hub.docker.com/r/linuxserver/docker-compose

Setup SSH key access from this device to the Server and Clients, so that the run script and docker context doesn't need passwords every time it runs.

Run run.sh with the Server and Client params. If server/client user and server/client ports are omitted then we will default to root and port 22

./run.sh -server 192.168.1.2 -serveruser some_cool_user -serverport 2222 -client 192.168.5.2 -clientuser some_other_user -clientport 1234

Checkout the output directory for the test results