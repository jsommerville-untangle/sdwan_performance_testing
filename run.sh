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
    esac
done

# Create the remote contexts using params
docker context create flent_remote_server --docker "host=ssh://$REMOTE_SERVER_USER@$REMOTE_SERVER:$REMOTE_SERVER_PORT"
docker context create flent_remote_client --docker "host=ssh://$REMOTE_CLIENT_USER@$REMOTE_CLIENT:$REMOTE_CLIENT_PORT"

# For some reason we need to set these as default before docker-compose will use them
# see: https://github.com/docker/compose/issues/7434
docker context use flent_remote_server
docker context use flent_remote_client

# Call compose with the context of the server and client, using the appropriate builds
docker-compose -f docker-compose.yml --context flent_remote_server up -d --build flent-server
docker-compose -f docker-compose.yml --context flent_remote_client up --build flent-client

# Remove the contexts
docker context rm flent_remote_server
docker context rm flent_remote_client