#!/bin/bash
#
# Creates the SSH config when needed
#
echo -en '\n' >> /root/.ssh/config
echo "Host ${RES_SRV}" >> /root/.ssh/config
echo -e "\tHostName ${RES_SRV}" >> /root/.ssh/config
echo -e "\tPort $RES_SSH_PORT" >> /root/.ssh/config
echo -e "\tUser $RES_SSH_USER" >> /root/.ssh/config
echo -e "\tIdentityFile /root/.ssh/id_perf">>/root/.ssh/config
echo -e "\tStrictHostKeyChecking no">>/root/.ssh/config
chmod 400 /root/.ssh/config