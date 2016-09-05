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

#$(echo $HOOK_PAYLOAD |jq '.error_message')