#!/bin/bash
#
# uploads all test results from the working directory
#

if [ -n "$RES_SRV" ]
then
    #Upload all results with datestamp to $RES_SRV using $RES_PORT and maybe a $RES_USER one day?
    rsync -rvz $1 $RES_SSH_USER@$RES_SRV:/data/
fi