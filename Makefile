AVAILABLE_MESHES ?= '{"meshes": ["kiali-test-depth", "kiali-test-breadth", "kiali-test-circle", "kiali-test-circle-callback", "kiali-test-hourglass", "kiali-test-depth-sink", "kiali-test-breadth-sink"]}'
NUM_SERVICES ?= 1
NUM_VERSIONS ?= 1
NUM_NAMESPACES ?= 1
ifeq (${NUM_NAMESPACES},1)
  PLAYBOOK=./test-service/deploy/ansible/deploy_test_meshes.yml
else
  PLAYBOOK=./test-service/deploy/ansible/deploy_test_multiple_namespaces_meshes.yml
endif

all:	build-service build-traffic-generator

build-service:
	@echo About to build the Kiali Test Service
	make -C test-service clean build docker-build

build-traffic-generator:
	@echo About to build the Kiali Test Traffic Generator
	make -C traffic-generator clean docker-build

openshift-deploy-kiali-test-depth:
	@echo About to deploy Kiali Test Depth to OpenShift
	ansible-playbook ${PLAYBOOK} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-depth"]}' -v

openshift-deploy-kiali-test-breadth:
	@echo About to deploy Kiali Test breadth to OpenShift
	ansible-playbook ${PLAYBOOK} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-breadth"]}' -v

openshift-deploy-kiali-test-circle:
	@echo About to deploy Kiali Test Circle to OpenShift
	ansible-playbook ${PLAYBOOK} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-circle"]}' -v

openshift-deploy-kiali-test-circle-callback:
	@echo About to deploy Kiali Test Circle Callback to OpenShift
	ansible-playbook ${PLAYBOOK} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-circle-callback"]}' -v

openshift-deploy-kiali-test-hourglass:
	# THIS IS NOT IMPLEMENTED YET FOR MULTI-NAMESPACE - @GBAUFAKE WILL FIX AND REMOVE THIS COMMENT
	@echo About to deploy Kiali Test Hourglass to OpenShift
	ansible-playbook ${PLAYBOOK} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-hourglass"]}' -v

openshift-deploy-kiali-test-depth-sink:
	@echo About to deploy Kiali Test Depth Sink to OpenShift
	ansible-playbook ${PLAYBOOK} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-depth-sink"]}' -v

openshift-deploy-kiali-test-breadth-sink:
	@echo About to deploy Kiali Test Breadth Sink to OpenShift
	ansible-playbook ${PLAYBOOK} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e '{"meshes": ["kiali-test-breadth-sink"]}' -v

openshift-deploy-all-meshes:
	@echo About to deploy all Kiali Test Meshes available to OpenShift
	ansible-playbook ${PLAYBOOK} -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e number_of_namespaces=${NUM_NAMESPACES} -e ${AVAILABLE_MESHES} -v
