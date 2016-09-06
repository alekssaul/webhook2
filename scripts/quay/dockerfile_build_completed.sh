#!/bin/bash
set -e

# Checks to see if there was a PR associated and executes logic

# Init Variables
logfile=${logfile:-/var/log/webhook.log}
confdir=${confdir:-/webhook/conf}
statusdir=${statusdir:-/webhook/status}
exec &> >(tee -a "$logfile")

echo `date` - Executing $0 

echo $HOOK_PAYLOAD > $statusdir/test/quay_build_completed.json
Github_Branch=$(echo $HOOK_PAYLOAD | jq '.trigger_metadata.ref' | tr -d '"' | awk 'BEGIN { FS = "/"} ; {print $3}')
if [ ! -f $statusdir/$Github_Branch/github_pr_open.json ] ; then
	echo `date` - ERROR: $statusdir/$Github_Branch/github_pr_open.json does not exist!
	exit 1;
fi


#$(echo $HOOK_PAYLOAD |jq '.error_message')

echo `date` - Done executing $0