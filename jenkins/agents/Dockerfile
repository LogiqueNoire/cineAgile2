FROM jenkins/inbound-agent:alpine3.22-jdk21
USER root

RUN apk add --no-cache bash curl unzip git

RUN curl -fsSL https://releases.hashicorp.com/terraform/1.14.0/terraform_1.14.0_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

USER jenkins
