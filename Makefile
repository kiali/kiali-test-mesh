AVAILABLE_MESHES ?= '{"meshes": ["kiali-test-depth", "kiali-test-breadth", "kiali-test-circle", "kiali-test-circle-callback", "kiali-test-hourglass", "kiali-test-depth-sink", "kiali-test-breadth-sink"]}'
DEPLOYMENT_TYPE ?= Deployment
NUM_SERVICES ?= 1
NUM_VERSIONS ?= 1
NUM_APPS ?= 1
NUM_NAMESPACES ?= 1
PLAYBOOK=./ansible/deploy_scale_mesh.yml

OPERATOR_IMAGE ?= kiali/kiali-test-mesh-operator:latest


all:	build-service build-traffic-generator

build-service:
	@echo About to build the Kiali Test Service
	make -C test-service clean build docker-build

build-traffic-generator:
	@echo About to build the Kiali Test Traffic Generator
	make -C traffic-generator clean docker-build

openshift-deploy-kiali-test-depth:
	@echo About to deploy Kiali Test Depth to OpenShift
	ansible-playbook ${PLAYBOOK} -e deployment_type=${DEPLOYMENT_TYPE} -e number_of_apps=${NUM_APPS} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-depth"]}' -v

openshift-deploy-kiali-test-breadth:
	@echo About to deploy Kiali Test breadth to OpenShift
	ansible-playbook ${PLAYBOOK} -e deployment_type=${DEPLOYMENT_TYPE} -e number_of_apps=${NUM_APPS} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-breadth"]}' -v

openshift-deploy-kiali-test-circle:
	@echo About to deploy Kiali Test Circle to OpenShift
	ansible-playbook ${PLAYBOOK} -e deployment_type=${DEPLOYMENT_TYPE} -e number_of_apps=${NUM_APPS} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-circle"]}' -v

openshift-deploy-kiali-test-circle-callback:
	@echo About to deploy Kiali Test Circle Callback to OpenShift
	ansible-playbook ${PLAYBOOK} -e deployment_type=${DEPLOYMENT_TYPE} -e number_of_apps=${NUM_APPS} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-circle-callback"]}' -v

openshift-deploy-kiali-test-hourglass:
	@echo About to deploy Kiali Test Hourglass to OpenShift
	ansible-playbook ${PLAYBOOK} -e deployment_type=${DEPLOYMENT_TYPE} -e number_of_apps=${NUM_APPS} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-hourglass"]}' -v

openshift-deploy-kiali-test-depth-sink:
	@echo About to deploy Kiali Test Depth Sink to OpenShift
	ansible-playbook ${PLAYBOOK} -e deployment_type=${DEPLOYMENT_TYPE} -e number_of_apps=${NUM_APPS} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-depth-sink"]}' -v

openshift-deploy-kiali-test-breadth-sink:
	@echo About to deploy Kiali Test Breadth Sink to OpenShift
	ansible-playbook ${PLAYBOOK} -e deployment_type=${DEPLOYMENT_TYPE} -e number_of_apps=${NUM_APPS} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-breadth-sink"]}' -v


operator-build:
	@echo Building operator
	cd operator/kiali-test-mesh-operator && operator-sdk build ${OPERATOR_IMAGE}
	docker push ${OPERATOR_IMAGE}


deploy-bookinfo-manual-sidecar:
	@echo Deploy Bookinfo with Manual Injection of the sidecar on Openshift
	oc create -f operator/kiali-test-mesh-operator/deploy/cr/manual-sidecar/bookinfo-cr.yaml -n kiali-test-mesh-operator 

deploy-bookinfo-automatic-sidecar:
	@echo Deploy Bookinfo with Automatic Injection of the sidecar on Openshift
	oc create -f operator/kiali-test-mesh-operator/deploy/cr/automatic-sidecar/bookinfo-cr.yaml -n kiali-test-mesh-operator 

deploy-complex-mesh-manual-sidecar:
	@echo Deploy Complex Mesh with Manual Injection of the sidecar on Openshift
	oc create -f operator/kiali-test-mesh-operator/deploy/cr/manual-sidecar/complex_mesh-cr.yaml -n kiali-test-mesh-operator

deploy-complex-mesh-automatic-sidecar:
	@echo Deploy Complex Mesh with Automatic Injection of the sidecar on Openshift
	oc create -f operator/kiali-test-mesh-operator/deploy/cr/automatic-sidecar/complex_mesh-cr.yaml -n kiali-test-mesh-operator


remove-bookinfo-manual-sidecar:
	@echo Deploy Bookinfo with Manual Injection of the sidecar on Openshift
	oc delete -f operator/kiali-test-mesh-operator/deploy/cr/manual-sidecar/bookinfo-cr.yaml -n kiali-test-mesh-operator

remove-bookinfo-automatic-sidecar:
	@echo Deploy Bookinfo with Automatic Injection of the sidecar on Openshift
	oc delete -f operator/kiali-test-mesh-operator/deploy/cr/automatic-sidecar/bookinfo-cr.yaml -n kiali-test-mesh-operator 

remove-complex-mesh-manual-sidecar:
	@echo Deploy Complex Mesh with Manual Injection of the sidecar on Openshift
	oc delete -f operator/kiali-test-mesh-operator/deploy/cr/manual-sidecar/complex_mesh-cr.yaml -n kiali-test-mesh-operator 

remove-complex-mesh-automatic-sidecar:
	@echo Deploy Complex Mesh with Automatic Injection of the sidecar on Openshift
	oc delete -f operator/kiali-test-mesh-operator/deploy/cr/automatic-sidecar/complex_mesh-cr.yaml -n kiali-test-mesh-operator



operator-deploy-openshift: operator-remove-openshift
	@echo Deploy Kiali Tesh Mesh Operator on Openshift
	oc new-project kiali-test-mesh-operator
	oc create -f operator/kiali-test-mesh-operator/deploy/bookinfo-crd.yaml -n kiali-test-mesh-operator 
	oc create -f operator/kiali-test-mesh-operator/deploy/complex_mesh-crd.yaml -n kiali-test-mesh-operator
	oc create -f operator/kiali-test-mesh-operator/deploy/service_account.yaml -n kiali-test-mesh-operator 
	oc create -f operator/kiali-test-mesh-operator/deploy/role_binding.yaml -n kiali-test-mesh-operator
	oc create -f operator/kiali-test-mesh-operator/deploy/operator.yaml -n kiali-test-mesh-operator 


operator-remove-openshift:
	@echo Remove Kiali Test Mesh Operator on Openshift
	oc delete --ignore-not-found=true -f operator/kiali-test-mesh-operator/deploy/bookinfo-crd.yaml -n kiali-test-mesh-operator
	oc delete --ignore-not-found=true -f operator/kiali-test-mesh-operator/deploy/complex_mesh-crd.yaml -n kiali-test-mesh-operator
	oc delete --ignore-not-found=true -f operator/kiali-test-mesh-operator/deploy/service_account.yaml -n kiali-test-mesh-operator
	oc delete --ignore-not-found=true -f operator/kiali-test-mesh-operator/deploy/role_binding.yaml -n kiali-test-mesh-operator
	oc delete --ignore-not-found=true -f operator/kiali-test-mesh-operator/deploy/operator.yaml -n kiali-test-mesh-operator
	oc delete namespace kiali-test-mesh-operator --ignore-not-found=true
