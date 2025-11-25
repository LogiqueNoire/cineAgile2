FROM jenkins/jenkins:jdk21

USER root
RUN apt-get update && \
    apt-get install -y curl unzip git && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

USER jenkins
