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

REMOTE_DEVICE=""
REMOTE_DEVICE_PORT=22
REMOTE_DEVICE_USER=root
REMOTE_DEVICE_PW=passwd

DEVICE="Unknown"
ORCH_CONFIG=""
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
        -rd|--remotedevice)
        REMOTE_DEVICE="$2"
        shift
        shift
        ;;
        -rdpw|--remotedevicepass)
        REMOTE_DEVICE_PW="$2"
        shift
        shift
        ;;
         -rdu|--remotedeviceuser)
        REMOTE_DEVICE_USER="$2"
        shift
        shift
        ;;
         -rdp|--remotedeviceport)
        REMOTE_DEVICE_PORT="$2"
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
        -oc|--config)
        ORCH_CONFIG="$2"
        shift
        shift
        ;;   
    esac
done

# Cleanup the environment files before running
rm .env

if [ -n "$DEVICE" ]
then
    echo TEST_DEVICE=$DEVICE>>.env
fi

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

if [ -n "$REMOTE_DEVICE" ]
then
    echo DEVICE_ADDR=$REMOTE_DEVICE>>.env
    echo DEVICE_PORT=$REMOTE_DEVICE_PORT>>.env
    echo DEVICE_USER=$REMOTE_DEVICE_USER>>.env
    echo DEVICE_PW=$REMOTE_DEVICE_PW>>.env
fi

echo ORCH_CONFIG=$ORCH_CONFIG>>.env

# Let the orchestrator handle python/run script tasks, unless explicitly told not to...
# If the orchestrator flag is not passed in, then source the env file and call run-tests.sh (Typically used for one off tests)
#
if [ -n "$ORCHESTRATOR" ]
then
    echo "Bringing up the orchestrator image..."
    docker-compose -f docker-compose.yml --env-file .env up -d --build perf-results-orchestrator
else
    source .env
    run-tests.sh
fi