#!/bin/bash
set -e

# Checks to see if there was a PR associated and executes logic

# Init Variables
logfile=${logfile:-/var/log/webhook.log}
confdir=${confdir:-/webhook/conf}
statusdir=${statusdir:-/webhook/status}
exec &> >(tee -a "$logfile")

if [ -f $confdir/secrets.sh ] ; then
	$confdir/secrets.sh
fi

echo `date` - Executing $0 

if [ ! -f $confdir/config.json ] ; then
	echo `date` - ERROR: $confdir/config.json does not exist!
	exit 1;
fi

Github_Branch=$(echo $HOOK_PAYLOAD | jq '.trigger_metadata.ref' | tr -d '"' | awk 'BEGIN { FS = "/"} ; {print $3}')

if [ ! -f $statusdir/$Github_Branch/github_pr_open.json ] ; then
	echo `date` - $statusdir/$Github_Branch/github_pr_open.json does not exist, nothing to do
	exit 1;
fi

# Test Github credentials
Github_attemptlogin=$(curl -s -u $Github_BOTUSER:$Github_BOTPassword https://api.github.com | jq '.message' | tr -d '"' )
if [ "$Github_attemptlogin" == "Bad credentials" ]; then
	echo `date` - ERROR: Could not authenticate to github
	exit 1;
fi

Github_CommentsURL=$(cat $statusdir/$Github_Branch/github_pr_open.json | jq '.pull_request.comments_url' | tr -d '"')
Quay_BuildPage=$(echo $HOOK_PAYLOAD | jq '.homepage' | tr -d '"' )
Github_Commit=$(echo $HOOK_PAYLOAD | jq '.trigger_metadata.commit' | tr -d '"' )
Quay_buildname=$(echo $HOOK_PAYLOAD | jq '.build_name' | tr -d '"' )
PR_RepoHTML=$(echo $HOOK_PAYLOAD | jq '.trigger_metadata.commit_info.url' | tr -d '"' | awk 'BEGIN { FS = "/commit"} ; {print $1}' )
KUBERNETES_NAMESPACE=$(cat $confdir/config.json | jq '.'\"$PR_RepoHTML\"'.KUBERNETES_NAMESPACE' | tr -d '"')
APP_PORT=$(cat $confdir/config.json | jq '.'\"$PR_RepoHTML\"'.APP_PORT' | tr -d '"')
KUBERNETES_ServiceType=$(cat $confdir/config.json | jq '.'\"$PR_RepoHTML\"'.KUBERNETES_ServiceType' | tr -d '"')

if [ "$KUBERNETES_NAMESPACE" == "null" ] ; then KUBERNETES_NAMESPACE=default ; fi

if [[ ! $(kubectl get namespace | grep $KUBERNETES_NAMESPACE) ]] ; then 
	kubectl create namespace $KUBERNETES_NAMESPACE 
fi

Quay_DockerURL=$(echo $HOOK_PAYLOAD | jq '.docker_url' | tr -d '"' )
Quay_DockerTAG=$(echo $HOOK_PAYLOAD | jq '.docker_tags[]' | tr -d '"' )
Quay_Name=$(echo $HOOK_PAYLOAD | jq '.name' | tr -d '"' )

kubectl run --namespace=$KUBERNETES_NAMESPACE \
	$Quay_Name-$Quay_buildname \
	--image=$Quay_DockerURL:$Quay_DockerTAG \
	--image-pull-policy=Always \
	--labels="App=$Quay_Name,GithubCommit=$Github_Commit" 

kubectl expose --namespace=$KUBERNETES_NAMESPACE \
	deployment $Quay_Name-$Quay_buildname \
	--port=$APP_PORT \
	--target-port=$APP_PORT \
	--type="$KUBERNETES_ServiceType"

echo $HOOK_PAYLOAD > $statusdir/$Github_Branch/quay_build_completed_$Quay_buildname.json

Github_POSTBody="Success: Quay.io Built the image for you. See: $Quay_BuildPage"

if [ "$KUBERNETES_ServiceType" == "LoadBalancer" ] ; then
	counter=0
	ExternalIPReady="{}"
	while [ "$ExternalIPReady" == "{}" ] && [ $counter -le 10 ]; do
		counter=$(expr $counter + 1)
		ExternalIPReady=$(kubectl --namespace=$KUBERNETES_NAMESPACE \
		get service $Quay_Name-$Quay_buildname -o json | jq '.status.loadBalancer')
		sleep 20
	done
	
	ExternalIPCheck=$(echo $ExternalIPReady | grep -c "hostname")
	if [ "$ExternalIPCheck" == "1" ]; then 
		ExternalIP=$(kubectl --namespace=$KUBERNETES_NAMESPACE \
		get service $Quay_Name-$Quay_buildname -o json | jq '.status.loadBalancer.ingress[].hostname' | tr -d '"'  )
		Github_POSTBody="$Github_POSTBody . Your application is available at $ExternalIP:$APP_PORT or http://$ExternalIP:$APP_PORT"
	fi
fi

echo $Github_POSTBody >> $logfile

# Post a comment with info
curl -s -u $Github_BOTUSER:$Github_BOTPassword -H "Content-Type: application/json" -X POST -d '{"body": "'"$Github_POSTBody"'""}' $Github_CommentsURL

echo `date` - Done executing $0
