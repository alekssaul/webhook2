FROM		almir/webhook:2.4.0
RUN			apk update && apk upgrade && \
			apk add curl bash jq && \
			curl -O https://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubectl && \
			mv kubectl /usr/local/bin/kubectl && \
			chmod +x /usr/local/bin/kubectl 
COPY 		hooks.json /etc/webhook/hooks.json
RUN			mkdir -p /webhook && \
			mkdir /webhook/scripts && \
			mkdir /webhook/status
COPY 		scripts	/webhook/scripts
ENV			WEBHOOKDIR /webhook

ENTRYPOINT ["/usr/local/bin/webhook", "-verbose", "-hooks=/etc/webhook/hooks.json", "-hotreload"]
