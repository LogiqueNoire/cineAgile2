FROM jenkins/inbound-agent:alpine3.22-jdk21
USER root

RUN apk add --no-cache bash curl unzip git python3 py3-pip util-linux

RUN pip install --break-system-packages --no-cache-dir awscli

RUN curl -fsSL https://releases.hashicorp.com/terraform/1.14.0/terraform_1.14.0_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

RUN pip install --break-system-packages --no-cache-dir checkov

USER jenkins
