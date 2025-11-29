FROM jenkins/inbound-agent:jdk17

USER root
RUN apt-get update && \
    apt-get install -y curl unzip git && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

USER jenkins
WORKDIR /var/jenkins_home