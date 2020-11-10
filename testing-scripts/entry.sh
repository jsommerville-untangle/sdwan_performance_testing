#!/bin/bash
#
# entry is the client entry script, runs downstream scripts 
#
/bin/bash setup-ssh.sh

NOW=$(date +"%m_%d_%y_%s")

RESULTS_DIR="${NOW}_${TEST_DEVICE}"

mkdir $RESULTS_DIR

/bin/bash flent-tests.sh $RESULTS_DIR

/bin/bash upload-results.sh $RESULTS_DIR