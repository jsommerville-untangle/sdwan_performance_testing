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


# Generate a keypair in tmp for Results and Client to communicate
ssh-keygen -q -t ed25519 -N '' -f ./id_perf <<< ""$'\n'"y" 2>&1 >/dev/null

# Create Env files before setting up containers
if [ -n "$RESULTS_SERVER" ]
then
    echo RES_SRV=$RESULTS_SERVER>>.env.client
    echo RES_SSH_PORT=13474>>.env.results
    echo RES_SSH_PORT=13474>>.env.client
    echo RES_SSH_PORT=13474>>.env.server
    echo RES_SSH_USER=root>>.env.client
else
    echo RES_SSH_PORT=22>>.env.results
    echo RES_SSH_PORT=22>>.env.server
    echo RES_SSH_PORT=22>>.env.client
fi

if [ -n "$REMOTE_SERVER" ]
then
    echo PERF_SRV=$REMOTE_SERVER>>.env.results
    echo PERF_SRV=$REMOTE_SERVER>>.env.client
    echo PERF_SRV=$REMOTE_SERVER>>.env.server
    echo h=$REMOTE_SERVER>>.env.client
    echo proto=TCP>>.env.client
fi


if [ -n "$RESULTS_SERVER" ]
then
    echo "Setting up results server..."
    docker context create perf_results_server --docker "host=ssh://$RESULTS_SERVER_USER@$RESULTS_SERVER:$RESULTS_SERVER_PORT"
    # ssh the temp keys too
    scp -P $RESULTS_SERVER_PORT /tmp/id_perf*  $RESULTS_SERVER_USER@$RESULTS_SERVER:/tmp/
    docker context use perf_results_server
    echo "Deploying results server..."
    docker-compose -f docker-compose.yml --context perf_results_server --env-file .env.results up -d --build perf-results-sshd
    docker-compose -f docker-compose.yml --context perf_results_server --env-file .env.results up -d --build perf-results-nginx
fi

if [ -n "$REMOTE_SERVER" ]
then
    echo "Configuring performance server..."
    docker context create perf_remote_server --docker "host=ssh://$REMOTE_SERVER_USER@$REMOTE_SERVER:$REMOTE_SERVER_PORT"
    docker context use perf_remote_server
    echo "Deploying performance server..."
    docker-compose -f docker-compose.yml --context perf_remote_server --env-file .env.server up -d --build perf-server
fi

if [ -n "$REMOTE_CLIENT" ]
then
    echo "Configuring performance client..."
    docker context create perf_remote_client --docker "host=ssh://$REMOTE_CLIENT_USER@$REMOTE_CLIENT:$REMOTE_CLIENT_PORT"
    docker context use perf_remote_client
    # ssh the temp keys too
    scp -P $REMOTE_CLIENT_PORT /tmp/id_perf* $REMOTE_CLIENT_USER@$REMOTE_CLIENT:/tmp/
    echo "Deploying performance client..."
    docker-compose -f docker-compose.yml --context perf_remote_client --env-file .env.client up --build perf-client
fi

# Set context back to default, just in case
docker context rm perf_results_server -f
docker context rm perf_remote_server -f
docker context rm perf_remote_client -f
docker context use default