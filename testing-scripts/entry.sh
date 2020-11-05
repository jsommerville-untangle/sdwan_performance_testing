#!/bin/bash
#
# entry is the client entry script, runs downstream scripts 
#
/bin/bash setup-ssh.sh

NOW=$(date +"%s_%m_%d_%y")

/bin/bash flent-tests.sh $NOW

/bin/bash upload-results.sh $NOW