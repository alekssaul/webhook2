FROM		almir/webhook:2.3.8
RUN			apk update && apk upgrade && \
			apk add curl bash && \
			curl -O https://storage.googleapis.com/kubernetes-release/release/v1.3.0/bin/linux/amd64/kubectl && \
			mv kubectl /usr/local/bin/kubectl && \
			chmod +x /usr/local/bin/kubectl 
COPY 		hooks.json.example /etc/webhook/hooks.json
COPY 		scripts	/var/scripts
RUN			chmod +x /var/scripts/kubedeploy.sh

ENTRYPOINT ["/usr/local/bin/webhook", "-verbose", "-hooks=/etc/webhook/hooks.json", "-hotreload"]