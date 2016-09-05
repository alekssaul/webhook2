#!/bin/bash
set -e

# Init Variables
logfile=${logfile:-/var/log/webhook_quay.log}

exec &> >(tee -a "$logfile")
echo `date` - Executing $0 
echo `date` - with HOOK_PAYLOAD : >> $logfile
echo ------------------ >> $logfile
echo $HOOK_PAYLOAD >> $logfile
echo ------------------ >> $logfile

# Determine what type of a trigger

Quay_BuildQueueCheck=$(echo $HOOK_PAYLOAD | jq '.is_manual')
Quay_RepoPushCheck=$(echo $HOOK_PAYLOAD |jq '.updated_tags')
Quay_BuildFailedCheck=$(echo $HOOK_PAYLOAD |jq '.error_message')

if [ $Quay_BuildQueueCheck == "false" ] || [ $Quay_BuildQueueCheck == "true" ] ; then
	echo `date` - Unsupported hook recieved 
	#${PWD}/dockerfile_build_queued.sh
elif [ "$Quay_RepoPushCheck" != "null" ]; then
	echo `date` - Unsupported hook recieved 
	#${PWD}/repository_push.sh
elif [ "$Quay_BuildFailedCheck" != "null" ]; then
	echo `date` - Unsupported hook recieved 
	#${PWD}/dockerfile_build_failed.sh
else
	${PWD}/dockerfile_build_completed.sh
fi

echo `date` - Done executing $0