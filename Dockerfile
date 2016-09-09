FROM		almir/webhook:2.4.0
RUN			apk update && apk upgrade && \
			apk add coreutils curl bash jq && \
			curl -O https://storage.googleapis.com/kubernetes-release/release/v1.4.0-alpha.3/bin/linux/amd64/kubectl && \
			mv kubectl /usr/local/bin/kubectl && \
			chmod +x /usr/local/bin/kubectl 
COPY 		hooks.json /etc/webhook/hooks.json
RUN			mkdir -p /webhook && \
			mkdir /webhook/scripts && \
			mkdir /webhook/status && \
			mkdir /webhook/conf
COPY 		scripts	/webhook/scripts
COPY		conf /webhook/conf
ENV			WEBHOOKDIR /webhook

ENTRYPOINT ["/usr/local/bin/webhook", "-verbose", "-hooks=/etc/webhook/hooks.json", "-hotreload"]
