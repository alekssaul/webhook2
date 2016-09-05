#!/bin/bash
set -e

# Main entrypoint for hooks coming from github
# Init Variables
logfile=${logfile:-/var/log/webhook.log}

exec &> >(tee -a "$logfile")

# Check X-GitHub-Event header execute action based on that
echo `date` - Executing $0 

Github_Event=$(echo $HOOK_HEADER | jq '.'\"X-Github-Event\"'' )

case $Github_Event in
	"\"pull_request\"")
		${PWD}/pullrequest.sh ;;	
	*) 
		echo `date` - Unsupported hook recieved ;;
esac

echo `date` - Done executing $0