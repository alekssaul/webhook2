#!/bin/bash
set -e

# Prepares manifests for deployment and takes necessary action to wait on Quay Build

# Init Variables
logfile=${logfile:-/var/log/webhook.log}
confdir=${confdir:-/webhook/conf}
statusdir=${statusdir:-/webhook/status}

exec &> >(tee -a "$logfile")

echo `date` - Executing $0 

# check pre-reqs
if [ ! -f $confdir/config.json ] ; then
	echo `date` - ERROR: $confdir/config.json does not exist!
	exit 1;
fi

PRnumber=$(echo $HOOK_PAYLOAD | jq '.number')
PRref=$(echo $HOOK_PAYLOAD | jq '.pull_request.head.ref')
echo $HOOK_PAYLOAD > $statusdir/$PR_ref/github_pr_edited.json

