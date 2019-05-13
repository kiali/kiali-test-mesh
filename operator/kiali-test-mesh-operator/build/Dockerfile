FROM quay.io/operator-framework/ansible-operator:v0.7.0



COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
USER root

RUN yum install bash-completion -y