AVAILABLE_MESHES ?= '{"meshes": ["kiali-test-depth", "kiali-test-breath", "kiali-test-circle", "kiali-test-circle-callback", "kiali-test-hourglass", "kiali-test-depth-sink", "kiali-test-breath-sink"]}'
MESHES ?= '{"meshes": ["kiali-test-depth", "kiali-test-breath", "kiali-test-circle-callback", "kiali-test-hourglass"]}'
NUM_SERVICES ?=1
NUM_VERSIONS ?=1


all:	build-service build-traffic-generator

build-service:
	@echo About to build the Kiali Test Service
	make -C test-service clean build docker-build

build-traffic-generator:
	@echo About to build the Kiali Test Traffic Generator
	make -C traffic-generator clean docker-build

openshift-deploy:
	@echo About to deploy a few sample projects to OpenShift
	ansible-playbook ./test-service/deploy/ansible/deploy_test_meshes.yml -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e ${MESHES} -v


openshift-deploy-all-meshes:
	@echo About to deploy a all projects available to OpenShift
	ansible-playbook ./test-service/deploy/ansible/deploy_test_meshes.yml -e number_of_services=${NUM_SERVICES} -e number_of_versions=${NUM_VERSIONS} -e ${AVAILABLE_MESHES} -v
