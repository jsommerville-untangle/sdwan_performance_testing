#!/bin/bash
#
# entry is the client entry script, runs downstream scripts 
#
/bin/bash setup-ssh.sh

/bin/bash flent-tests.sh

/bin/bash upload-results.sh