#!/bin/bash
# run-tests.sh will create the results, server, client containers and run tests
#
#
ssh-keygen -q -t ed25519 -N '' -f ./id_perf <<< ""$'\n'"y" 2>&1 >/dev/null

if [ -n "$RES_SRV" ]
then
    echo "Setting up results server..."
    docker context create perf_results_server --docker "host=ssh://$RES_SRV_USER@$RES_SRV:$RES_SRV_PORT"
    docker context use perf_results_server
    echo "Deploying results server..."
    docker-compose -f docker-compose.yml --context perf_results_server --env-file .env up -d --build perf-results-sshd
    docker-compose -f docker-compose.yml --context perf_results_server --env-file .env up -d --build perf-results-nginx
fi

if [ -n "$PERF_SRV" ]
then
    echo "Configuring performance server..."
    docker context create perf_remote_server --docker "host=ssh://$PERF_SRV_USER@$PERF_SRV:$PERF_SRV_PORT"
    docker context use perf_remote_server
    echo "Deploying performance server..."
    docker-compose -f docker-compose.yml --context perf_remote_server --env-file .env up -d --build perf-server
fi

if [ -n "$PERF_CLIENT" ]
then
    echo "Configuring performance client..."
    docker context create perf_remote_client --docker "host=ssh://$PERF_CLIENT_USER@$PERF_CLIENT:$PERF_CLIENT_PORT"
    docker context use perf_remote_client
    echo "Deploying performance client..."
    docker-compose -f docker-compose.yml --context perf_remote_client --env-file .env up --build perf-client
fi

# Set context back to default, just in case
docker context rm perf_results_server -f
docker context rm perf_remote_server -f
docker context rm perf_remote_client -f
docker context use default
