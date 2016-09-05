#!/bin/bash
set -e

# Prepares manifests for deployment and takes necessary action to wait on Quay Build

# Init Variables
logfile=${logfile:-/var/log/webhook.log}

exec &> >(tee -a "$logfile")
echo `date` - Executing $0 

PRnumber=$(echo $HOOK_PAYLOAD | jq '.number')
PRref=$(echo $HOOK_PAYLOAD | jq '.pull_request.head.ref')