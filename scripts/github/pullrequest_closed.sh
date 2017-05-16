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

# Get State
PR_number=$(echo $HOOK_PAYLOAD | jq '.number' | tr -d '"')
PR_ref=$(echo $HOOK_PAYLOAD | jq '.pull_request.head.ref' | tr -d '"' )
Github_CommentsURL=$(cat $statusdir/$PR_ref/github_pr_open.json | jq '.pull_request.comments_url' | tr -d '"')
PR_RepoHTML=$(echo $HOOK_PAYLOAD | jq '.pull_request.base.repo.html_url' | tr -d '"')
KUBERNETES_NAMESPACE=$(cat $confdir/config.json | jq '.'\"$PR_RepoHTML\"'.KUBERNETES_NAMESPACE' | tr -d '"')
Quay_Name=$(echo $HOOK_PAYLOAD | jq '.name' | tr -d '"' )


mkdir -p $statusdir/$PR_ref 2> /dev/stdout 1> /dev/null
echo $HOOK_PAYLOAD > $statusdir/$PR_ref/github_pr_closed.json

# Test Github credentials
Github_attemptlogin=$(curl -s -u $Github_BOTUSER:$Github_BOTPassword https://api.github.com | jq '.message' | tr -d '"' )
if [ "$Github_attemptlogin" == "Bad credentials" ]; then
	echo `date` - ERROR: Could not authenticate to github
	exit 1;
fi

# Remove Deployments
pushd $statusdir/$PR_ref
Quay_files=$(ls quay_build_completed_*.json)
for build in $Quay_files; do 
	buildid=$(echo $build | sed -e 's/quay_build_completed_//g' | sed -e 's/.json//g' )
	Quay_Name=$(cat $build | jq '.name' | tr -d '"' )
	echo `date` - Removing $buildid from $KUBERNETES_NAMESPACE
	kubectl --namespace=$KUBERNETES_NAMESPACE delete \
		service $Quay_Name-$buildid 
	kubectl --namespace=$KUBERNETES_NAMESPACE delete \
		deployment $Quay_Name-$buildid 
done
popd 


# Let the User know
Github_POSTBody="Looks like the Pull Request is closed, all Kubernetes objects associated to this PR has been removed"
curl -s -u $Github_BOTUSER:$Github_BOTPassword -H "Content-Type: application/json" -X POST -d '{"body": "'"$Github_POSTBody"'""}' $Github_CommentsURL

echo `date` - Done executing $0