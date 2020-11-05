#!/bin/bash
#
# uploads all test results from the working directory
#

#Upload all results with datestamp to $RES_SRV using $RES_PORT and maybe a $RES_USER one day?
NOW=$(date +"%s_%m_%d_%y")
rsync -rvz * $RES_SSH_USER@$RES_SRV:/data/$NOW/