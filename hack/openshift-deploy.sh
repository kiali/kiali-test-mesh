#!/bin/bash

set -x

# Get the directory of this file
SOURCE_ROOT=$(dirname "${BASH_SOURCE}")/..

# Use the current project as the default if no namespace is specified
namespace=`oc project --short`

while getopts ":n:c:" opt; do
  case $opt in
    n)
      namespace=${OPTARG}
      ;;
    c)
      config=${OPTARG}
      ;;
    \?)
      echo "Invalid option ${opt}"
      ;;
  esac
done

echo "About to deploy a tesh mesh to namespace '${namespace}' with configuration file '${config}'"

function setup {
  namespace=${1}

  # create the new namespace, this will cause an error to be displayed if it already exists, but we can ignore for now.
  oc new-project ${namespace} || true

  # get rid of existing deployments
  oc delete all,configmap -n ${namespace} --selector=kiali-test
  
  # grant the namespace the permissions required for envoy to run properly
  oc adm policy add-scc-to-user privileged -z default -n ${namespace}
}

function deploy_services {
  namespace=${1}
  
  template=${SOURCE_ROOT}/test-service/deploy/openshift/test-app-template.yaml

  # deploy services
  for i in a b c d e f; do
   oc process -f ${template} -p SERVICE_NAME=${i}  | istioctl kube-inject -f - | oc create -n ${namespace} -f -
  done
}

function deploy_traffic_generator {
  namespace=${1}
  
  template=${SOURCE_ROOT}/traffic-generator/openshift/traffic-generator.yaml
 
  oc create -f ${template} -n ${namespace}
}

function deploy_traffic_configmap {
  namespace=${1}
  configmapfile=${2}

  oc create -f ${configmapfile} -n ${namespace}
}

setup ${namespace}
deploy_services ${namespace}
deploy_traffic_generator ${namespace}
deploy_traffic_configmap ${namespace} ${config}
