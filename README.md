Based on [webhook](https://github.com/adnanh/webhook/) and Webhook contrib projects. GoogleCloudPlatform\continuous-deployment on-kubernetes and Kubernetes\contrib\scale-demo prjects

### Webhook for Quay Enterprise & Kubernetes Demo

This repo contains Webhook code based on Adnanh's implementation. It is inteded to be used for Quay Enterprise to Kubernetes Continuous Delivery demos. 

### Setup

- Setup Kubernetes
- Deploy Jenkins
- Deploy Webhook
- Configure Quay.io trigger to issue hooks against webhook service

## Folder Structure

- Dockerfile : support building custom webhook container
- Manifests: Manifests used for webhook (this) application on Kubernetes
- Scripts: Bash scripts and manifests used for creating an application on Kubernetes
- Scale-demo: Files intended to be used for autoscaling demo, which is not currently implemented

```
kubectl create namespace webhook
kubectl --namespace=webhook create -f manifests replicationcontroller.yaml
kubectl --namespace=webhook create -f manifests service.yaml
kubectl --namespace=webhook create configmap kubeconfig --from-file="$HOME/.dockercfg"
```