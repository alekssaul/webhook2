#!/bin/bash
set -e

echo `date` -  Started GitHub to Kubernetes script 
echo `date` -  Recieved arguments $1 $2 

# Init Variables
logfile=${logfile:-var/log/webhook.log}

# Init Constants
APPDIR=${PWD}

echo $HOOK_PAYLOAD
