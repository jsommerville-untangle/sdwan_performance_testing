#!/bin/bash
# Deploy Docker containers to two remote locations and have them run sdwan performance tests
#
#
#
#

REMOTE_SERVER=""
REMOTE_SERVER_PORT=22
REMOTE_SERVER_USER=root

REMOTE_CLIENT=""
REMOTE_CLIENT_PORT=22
REMOTE_CLIENT_USER=root

RESULTS_SERVER=""
RESULTS_SERVER_PORT=22
RESULTS_SERVER_USER=root

for arg in "$@"
do
    case $arg in
        -s|--server)
        REMOTE_SERVER="$2"
        shift
        shift
        ;;
        -su|--serveruser)
        REMOTE_SERVER_USER="$2"
        shift
        shift
        ;;
        -sp|--serverport)
        REMOTE_SERVER_PORT="$2"
        shift
        shift
        ;;
        -c|--client)
        REMOTE_CLIENT="$2"
        shift
        shift
        ;;
        -cp|--clientport)
        REMOTE_CLIENT_PORT="$2"
        shift
        shift
        ;;
        -cu|--clientuser)
        REMOTE_CLIENT_USER="$2"
        shift
        shift
        ;;
        -rs|--resultserver)
        RESULTS_SERVER="$2"
        shift
        shift
        ;;
        -ru|--resultserveruser)
        RESULTS_SERVER_USER="$2"
        shift
        shift
        ;;
        -rp|--resultserverport)
        RESULTS_SERVER_PORT="$2"
        shift
        shift
        ;;
        
    esac
done

# Cleanup the environment files before running
rm .env.results
rm .env.client
rm .env.server

touch .env.results
touch .env.client
touch .env.server

# Create Env files before setting up containers
if [ -n "$RESULTS_SERVER" ]
then
    echo RES_SRV=$RESULTS_SERVER>>.env.results
fi

if [ -n "$REMOTE_SERVER" ]
then
    echo PERF_SRV=$REMOTE_SERVER>>.env.results
    echo PERF_SRV=$REMOTE_SERVER>>.env.client
fi
if [ -n "$RESULTS_SERVER" ]
then
    echo "Setting up results server..."
fi

if [ -n "$REMOTE_SERVER" ]
then
    echo "Configuring performance server..."
    docker context create perf_remote_server --docker "host=ssh://$REMOTE_SERVER_USER@$REMOTE_SERVER:$REMOTE_SERVER_PORT"
    docker context use perf_remote_server
    echo "Deploying performance server..."
    docker-compose -f docker-compose.yml --context perf_remote_server up -d --build perf-server
    docker context rm perf_remote_server
fi

if [ -n "$REMOTE_CLIENT" ]
then
    echo "Configuring performance client..."
    docker context create perf_remote_client --docker "host=ssh://$REMOTE_CLIENT_USER@$REMOTE_CLIENT:$REMOTE_CLIENT_PORT"
    docker context use perf_remote_client
    echo "Deploying performance client..."
    docker-compose -f docker-compose.yml --context perf_remote_client up --build perf-client
    docker context rm perf_remote_client
fi

# Set context back to default, just in case
docker context use default