FROM jenkins/jenkins:lts

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

USER root

RUN apt-get update && \
    apt-get install -y docker.io python3 python3-pip curl unzip

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN curl -L -o tofu.tar.gz "https://github.com/opentofu/opentofu/releases/download/v1.10.4/tofu_1.10.4_linux_amd64.tar.gz" && \
    tar -xzf tofu.tar.gz && \
    mv tofu /usr/local/bin/ && \
    chmod +x /usr/local/bin/tofu && \
    rm tofu.tar.gz

USER jenkins
