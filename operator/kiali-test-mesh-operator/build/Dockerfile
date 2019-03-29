FROM quay.io/operator-framework/ansible-operator:v0.6.0



COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
USER root

RUN yum install bash-completion -y

# install the oc client tools
RUN rpm -ivh http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin/origin-clients-3.11.0-1.el7.git.0.62803d0.x86_64.rpm

USER 1001