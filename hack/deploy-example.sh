# Simple script to deploy a bunch of simple example service meshes

# Fail on error
set -e
#set -x

# Get the root directory
SOURCE_ROOT=$(dirname "${BASH_SOURCE}")/..
# Get the template file
TEMPLATE=$SOURCE_ROOT/deploy/openshift/test-app-template.yaml

function deploy_depth {
  namespace="kiali-test-depth"
  deploy_applications ${namespace};

  service_ip=$(oc -n ${namespace} get svc a --template='{{.spec.clusterIP}}')

  curl http://${service_ip}/route?path=a,b,c,d,e,f
}

function deploy_breadth {
  namespace="kiali-test-breath"
  deploy_applications ${namespace};

  service_ip=$(oc -n ${namespace} get svc a --template='{{.spec.clusterIP}}')

  for i in a b c d e f; do
    curl http://${service_ip}/route?path=${i}
  done
}

function deploy_circle {
  namespace="kiali-test-circle"
  deploy_applications ${namespace};

  service_ip=$(oc -n ${namespace} get svc a --template='{{.spec.clusterIP}}')

  curl http://${service_ip}/route?path=a,b,c,d,e,f,a
}

function deploy_circle_callback {
  namespace="kiali-test-circle-callback"
  deploy_applications ${namespace};

  service_ip=$(oc -n ${namespace} get svc a --template='{{.spec.clusterIP}}')

  curl http://${service_ip}/route?path=a,b,c,d,e,f,a
  curl http://${service_ip}/route?path=a,f,e,d,c,b,a
}


function deploy_hourglass {
  namespace="kiali-test-hourglass"
  deploy_applications ${namespace}
  
  service_ip=$(oc -n ${namespace} get svc a --template='{{.spec.clusterIP}}')
  
  curl http://${service_ip}/route?path=a,b,c,d,e
  curl http://${service_ip}/route?path=a,c,e
}

function deploy_box {
  namespace="kiali-test-box"
  deploy_applications ${namespace}

  service_ip=$(oc -n ${namespace} get svc a --template='{{.spec.clusterIP}}')

  curl http://${service_ip}/route?path=a,b,d,c,a,d,c,b
}

function deploy_depthsink {
  namespace="kiali-test-depth-sink"
  deploy_applications ${namespace}

  service_ip=$(oc -n ${namespace} get svc a --template='{{.spec.clusterIP}}')

  curl http://${service_ip}/route?path=a,f
  curl http://${service_ip}/route?path=a,b,f
  curl http://${service_ip}/route?path=a,b,c,f
  curl http://${service_ip}/route?path=a,b,c,d,f
  curl http://${service_ip}/route?path=a,b,c,d,e,f
}

function deploy_breadthsink {
  namespace="kiali-test-breadth-sink"
  deploy_applications ${namespace}

  service_ip=$(oc -n ${namespace} get svc a --template='{{.spec.clusterIP}}')

  for i in a b c d e ; do
    curl http://${service_ip}/route?path=${i},f
  done
}


function deploy_applications {
  namespace=${1}

  # delete the project if it already exists
  # oc delete project ${namespace} --ignore-not-found
  # create the new namespace, this will cause an error to be displayed if it already exists, but we can ignore for now.
  oc new-project ${namespace} || true
  
  # delete everything in this project
  #oc delete all -n ${namespace} --ignore-not-found --all 

  # grant the namespace the permissions required for envoy to run properly
  oc adm policy add-scc-to-user privileged -z default -n ${namespace}

  for i in a b c d e f; do
   oc process -f ${TEMPLATE} -p SERVICE_NAME=${i} | istioctl kube-inject -f - | oc apply -n ${namespace} -f -  
  done
 
  wait_for_all_pods ${namespace}
}

function wait_for_all_pods {
  # quick and dirty hack to see if all the pods are running or not
  namespace=${1}

  start_time=$(date +%s)
  while [ $(( $(date +%s) - ${start_time} )) -le 360 ]; do
    pods_ready=$(oc get pods -n ${namespace} | grep -i kiali-test-service | awk '{print $2}')
    counter=0;
    for pod_ready in $pods_ready; do
      if [[ ${pod_ready} == "2/2" ]]; then
        ((counter++)) || true
      fi
    done
    if [[ ${counter} == 6 ]]; then
      echo "All pods are started"
      sleep 2
      return
    else
      echo "All pods are not started yet (${counter}/6). Will try again"
    fi
    sleep 1
  done

  echo "ERROR: the pods did not start up in time."
  echo "Aborting"
  exit 1
}

deploy_depth;
deploy_breadth;
deploy_circle;
deploy_circle_callback;
deploy_hourglass;
deploy_box;
deploy_breadthsink;
deploy_depthsink;
