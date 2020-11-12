#!/bin/bash
# Deploy Docker containers to two remote locations and have them run sdwan performance tests
# this script is responsible for building the .ENV file and creating the entry into the Orchestration container
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

DEVICE="Unknown"

ORCHESTRATOR=""

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
        -d|--device)
        DEVICE="$2"
        shift
        shift
        ;;
        -o|--orchestrator)
        ORCHESTRATOR="$2"
        shift
        shift
        ;;        
    esac
done

# Cleanup the environment files before running
rm .env

# Generate a keypair in tmp for Results and Client to communicate
#ssh-keygen -q -t ed25519 -N '' -f ./id_perf <<< ""$'\n'"y" 2>&1 >/dev/null

echo TEST_DEVICE=$DEVICE>>.env
# Create Env files before setting up containers
if [ -n "$RESULTS_SERVER" ]
then
    # These are used for docker context creation
    echo RES_SRV=$RESULTS_SERVER>>.env
    echo RES_SRV_USER=$RESULTS_SERVER_USER>>.env
    echo RES_SRV_PORT=$RESULTS_SERVER_PORT>>.env

    # These are used for RSync SSH config
    echo RES_SSH_PORT=13474>>.env
    echo RES_SSH_USER=root>>.env
else
    echo RES_SSH_PORT=22>>.env
fi

if [ -n "$REMOTE_SERVER" ]
then
    echo PERF_SRV=$REMOTE_SERVER>>.env
    echo PERF_SRV_PORT=$REMOTE_SERVER_PORT>>.env
    echo PERF_SRV_USER=$REMOTE_SERVER_USER>>.env
fi

if [ -n "$REMOTE_CLIENT" ]
then
    echo PERF_CLIENT=$REMOTE_CLIENT>>.env
    echo PERF_CLIENT_PORT=$REMOTE_CLIENT_PORT>>.env
    echo PERF_CLIENT_USER=$REMOTE_CLIENT_USER>>.env
fi

# Let the orchestrator handle python/run script tasks, unless explicitly told not to...
# If the orchestrator image is not passed in, then source the env file and call run-tests.sh (Typically used for one off tests)
#
if [ -n "$ORCHESTRATOR" ]
then
    echo "Bringing up the orchestrator image..."
    docker-compose -f docker-compose.yml --env-file .env up -d --build perf-results-orchestrator
else
    source .env
    run-tests.sh
fi