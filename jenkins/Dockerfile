FROM jenkins/jenkins:jdk21

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

USER root

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY install-plugins.sh /usr/local/bin/install-plugins.sh

RUN chmod +x /usr/local/bin/install-plugins.sh
RUN /usr/local/bin/install-plugins.sh /usr/share/jenkins/ref/plugins.txt

EXPOSE 8080 50000