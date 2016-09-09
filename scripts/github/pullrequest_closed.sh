#!/bin/bash
set -e

# Prepares manifests for deployment and takes necessary action to wait on Quay Build

# Init Variables
logfile=${logfile:-/var/log/webhook.log}
confdir=${confdir:-/webhook/conf}
statusdir=${statusdir:-/webhook/status}

exec &> >(tee -a "$logfile")

if [ -f $confdir/secrets.sh ] ; then
	$confdir/secrets.sh
fi

echo `date` - Executing $0 

# check pre-reqs
if [ ! -f $confdir/config.json ] ; then
	echo `date` - ERROR: $confdir/config.json does not exist!
	exit 1;
fi

PR_number=$(echo $HOOK_PAYLOAD | jq '.number' | tr -d '"')
PR_ref=$(echo $HOOK_PAYLOAD | jq '.pull_request.head.ref' | tr -d '"' )
echo $HOOK_PAYLOAD > $statusdir/$PR_ref/github_pr_closed.json

# Test Github credentials
Github_attemptlogin=$(curl -s -u $Github_BOTUSER:$Github_BOTPassword https://api.github.com | jq '.message' | tr -d '"' )
if [ "$Github_attemptlogin" == "Bad credentials" ]; then
	echo `date` - ERROR: Could not authenticate to github
	exit 1;
fi



