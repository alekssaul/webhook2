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
if [ ! -f $confdir/githubtoquay.json ] ; then
	echo `date` - ERROR: $confdir/githubtoquay.json does not exist!
	exit 1;
fi

PR_number=$(echo $HOOK_PAYLOAD | jq '.number' | tr -d '"')
PR_ref=$(echo $HOOK_PAYLOAD | jq '.pull_request.head.ref' | tr -d '"' )
PR_CreatedTime=$(echo $HOOK_PAYLOAD | jq '.pull_request.created_at' | tr -d '"')
PR_CreatedUnixTime=$(date --date=$PR_CreatedTime +"%s")
# adjust for time delay between webhook starts between self and Quay.io
PR_AdjustedUnixTime=$(expr $PR_CreatedUnixTime - 30)
PR_RepoHTML=$(echo $HOOK_PAYLOAD | jq '.pull_request.base.repo.html_url' | tr -d '"')
Quay_Repo=$(cat $confdir/githubtoquay.json | jq '.githubrepos.'\"$PR_RepoHTML\"'' | tr -d '"')
Quay_BuilderAPI=$(echo $Quay_Repo | sed -e 's/https:\/\/quay.io/https:\/\/quay.io\/api\/v1\/repository/g' | xargs -I {} echo {}/build/?since=$PR_AdjustedUnixTime)
echo `date` - Checking Quay API: $Quay_BuilderAPI
Quay_BuilderStatus=$(curl -s $Quay_BuilderAPI)
Quay_BuildStatus=$(echo $Quay_BuilderStatus | jq '.builds[].phase' | tr -d '"' )
PR_Repo=$(jq '.pull_request.base.repo.full_name' | tr -d '"' )
echo `date` - Quay Status: $Quay_BuildStatus

case $Quay_BuildStatus in
	"build-scheduled")
		mkdir -p $statusdir/$PR_ref
		echo $HOOK_PAYLOAD > $statusdir/$PR_Repo/$PR_ref/github_pr_open.json
		;;
	*)
		echo `date` - Quay Builder in unknown state ;;
esac

echo `date` - Done executing $0