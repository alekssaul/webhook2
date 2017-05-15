#!/bin/bash
# Copyright 2015 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create the loadbots
ProductionVersion=$(kubectl --namespace=hello-world  get rc | grep helloworld-production | awk -F '-' '{print $3}' | awk '{print $1}')
RollingVersion=$(expr $ProductionVersion + 1)
sed -i 's@production-10@'$ProductionVersion'@g' www/pods.html.tmp
sed -i 's@production-11@'$RollingVersion'@g' www/pods.html.tmp
sed -i 's@production-10@'$ProductionVersion'@g' www/pods.js.tmp
sed -i 's@production-11@'$RollingVersion'@g' www/pods.js.tmp
cp www/pods.js.tmp www/pods.js
cp www/pods.html.tmp www/pods.html

kubectl create -f vegeta-rc.yaml

# Create the data aggregator
kubectl create -f aggregator-rc.yaml
kubectl expose rc aggregator --port=8080
