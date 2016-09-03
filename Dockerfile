FROM		almir/webhook:2.4.0
RUN			apk update && apk upgrade && \
			apk add curl bash && \
			curl -O https://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubectl && \
			mv kubectl /usr/local/bin/kubectl && \
			chmod +x /usr/local/bin/kubectl 
COPY 		hooks.json /etc/webhook/hooks.json
RUN			mkdir -p /webhook && \
			mkdir /webhook/scripts
COPY 		scripts	/webhook/scripts
RUN			chmod +x /webhook/scripts/quay/kubedeploy.sh && \
			chmod +x /webhook/scripts/github/github.sh

ENTRYPOINT ["/usr/local/bin/webhook", "-verbose", "-hooks=/etc/webhook/hooks.json", "-hotreload"]
