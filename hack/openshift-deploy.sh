#!/bin/bash

set -x

# Settings for creating many versions to each service
RANDOM_VERSIONS=${RANDOM_VERSIONS:-false}
MAX_NUMBER_OF_VERSIONS=${MAX_NUMBER_OF_VERSIONS:-5}

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

  local service_template=${SOURCE_ROOT}/test-service/deploy/openshift/service-template.yaml
  local app_template=${SOURCE_ROOT}/test-service/deploy/openshift/app-template.yaml

  # deploy services
  for i in a b c d e f; do
   oc process -f ${service_template} -p SERVICE_NAME=${i} | istioctl kube-inject -f - | oc create -n ${namespace} -f -
  done

  if [[ ${RANDOM_VERSIONS} != 'false' ]]; then
    let number_of_versions=$(( ( RANDOM % $MAX_NUMBER_OF_VERSIONS ) + 1 ))
    echo $number_of_versions
  else
    let number_of_versions=$MAX_NUMBER_OF_VERSIONS
  fi

  # Deploy other versions for some of the services
  for i in a b c d e f; do
    for n in $(seq 1 $number_of_versions); do
      oc process -f ${app_template} -p SERVICE_NAME=${i} -p SERVICE_VERSION=v${n} | istioctl kube-inject -f - | oc create -n ${namespace} -f -
    done
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
