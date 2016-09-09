#!/bin/bash
set -e
export logfile=/var/log/webhook.log
export ApplicationNamespace=hello-world
export APPDIR=${PWD}

echo `date` -  Started KubeDeploy script  
echo `date` -  Recieved arguments $1 $2  
imagehook=$2
imagehook=${imagehook#[}
imagehook=${imagehook%]}
productionreplica=4
canaryreplica=1


if [[ ! $(echo $1 | grep aleks_saul/hello_world) ]]; then 
	echo `date` - Unknown repository  
	exit ;
fi

function DeployProd {
	echo `date` - Starting Production Deployment $imagehook... 
	cp $APPDIR/manifest-helloworld-deployment.yaml manifest-helloworld-$imagehook-deployment.yaml 
	sed -i 's@\[tag\]@'$imagehook'@g' manifest-helloworld-$imagehook-deployment.yaml 
	sed -i 's@\[stage\]@'production'@g' manifest-helloworld-$imagehook-deployment.yaml
	sed -i 's@\[replicas\]@'$productionreplica'@g' manifest-helloworld-$imagehook-deployment.yaml

	if [[ ! $(kubectl --namespace\=$ApplicationNamespace get deployment | grep production) ]] ; then
		echo `date` - Didn\'t find Production Deployment, creating the initial one ... 
		echo `date` - Executing : kubectl --namespace=$ApplicationNamespace create -f $APPDIR/manifest-helloworld-$imagehook-deployment.yaml	
		kubectl --namespace=$ApplicationNamespace create -f $APPDIR/manifest-helloworld-$imagehook-deployment.yaml	
	else
		echo `date` - Updating Production deployment to : $imagehook... 		
		echo `date` - Executing : kubectl --namespace=$ApplicationNamespace set image deployment/helloworld-production helloworld=quay.io/aleks_saul/hello_world:$imagehook
		kubectl --namespace=$ApplicationNamespace set image deployment/helloworld-production helloworld=quay.io/aleks_saul/hello_world:$imagehook

		echo `date` - Removing Canary deployment ... 
		echo `date` - Executing : kubectl --namespace=$ApplicationNamespace delete deployment/helloworld-canary
		kubectl --namespace=$ApplicationNamespace delete deployment/helloworld-canary

	fi	

}

function DeployCanary {	
	echo `date` - Starting Canary Deployment $imagehook... 	
	cp $APPDIR/manifest-helloworld-deployment.yaml manifest-helloworld-$imagehook-deployment.yaml 
	sed -i 's@\[tag\]@'$imagehook'@g' manifest-helloworld-$imagehook-deployment.yaml 
	sed -i 's@\[stage\]@'canary'@g' manifest-helloworld-$imagehook-deployment.yaml
	sed -i 's@\[replicas\]@'$canaryreplica'@g' manifest-helloworld-$imagehook-deployment.yaml

	if [[ ! $(kubectl --namespace\=$ApplicationNamespace get deployment | grep canary) ]] ; then
		echo `date` - Didn\'t find Canary Deployment, creating the initial one ... 
		echo `date` - Executing : kubectl --namespace=$ApplicationNamespace create -f $APPDIR/manifest-helloworld-$imagehook-deployment.yaml
		kubectl --namespace=$ApplicationNamespace create -f $APPDIR/manifest-helloworld-$imagehook-deployment.yaml
	else		
		echo `date` - Updating Canary deployment to $imagehook...
		echo `date` - Executing : kubectl --namespace=$ApplicationNamespace set image deployment/helloworld-canary helloworld=quay.io/aleks_saul/hello_world:$imagehook
		kubectl --namespace=$ApplicationNamespace set image deployment/helloworld-canary helloworld=quay.io/aleks_saul/hello_world:$imagehook
	fi	
	
}

function DeployFederation {	
	echo `date` - Starting Federation Deployment $imagehook... 	
	
}


function TestKubernetes {
	echo `date` - Testing Kubernetes Connectivity ...  
	if [[ $(kubectl get cs | grep ok) ]]; then
		echo `date` - Kubernetes cluster seem to be health  
		
		if [[ $(kubectl get namespace | grep $ApplicationNamespace) ]] ; then
			echo `date` - Found namespace: $ApplicationNamespace  	
		else
			echo `date` - Couldn\'t find namespace, creating it now   
			kubectl create namespace $ApplicationNamespace	
		fi

		if [[ ! $(kubectl --namespace\=$ApplicationNamespace get svc) ]] ; then
			echo `date` - Didn\'t find service for $ApplicationNamespace creating one now
			kubectl --namespace=$ApplicationNamespace create -f $APPDIR/manifest-helloworld-service.yaml
		fi

	else 
		echo `date` - Not a valid response from \"kubectl get cluster-health\" 
		exit ;
	fi
}

TestKubernetes

if [[ "$imagehook" != "${imagehook/production}" ]]; then 
	echo `date` - Found Production Deployment request  
	DeployProd
elif [[ "$imagehook" != "${imagehook/canary}" ]]; then  
	echo `date` - Found Canary Deployment request  
	DeployCanary
elif [[ "$imagehook" != "${imagehook/global}" ]]; then  
	echo `date` - Found Global deployment request  
	DeployFederation
else 
	echo `date` - Unknown deployment request  
	exit ; 
fi
