#!/bin/bash
set -e

# Init Variables
logfile=${logfile:-/var/log/webhook.log}

exec &> >(tee -a "$logfile")
echo `date` - Executing $0 
echo `date` - with HOOK_PAYLOAD : >> $logfile
echo ------------------ >> $logfile
echo $HOOK_PAYLOAD >> $logfile
echo ------------------ >> $logfile

# Check Kubernetes cluster health
function TestKubernetes {
	echo `date` - Testing Kubernetes Connectivity ...  
	if [[ $(kubectl get cs | grep ok) ]]; then
		echo `date` - Kubernetes cluster seem to be health  
	else 
		echo `date` - Not a valid response from \"kubectl get cluster-health\" 
		exit ;
	fi
}

#TestKubernetes


