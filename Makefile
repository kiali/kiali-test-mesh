all:	build-service build-traffic-generator

build-service:
	@echo About to build the Kiali Test Service
	make -C test-service clean build docker-build 

build-traffic-generator:
	@echo About to build the Kiali Test Traffic Generator
	make -C traffic-generator clean docker-build

openshift-deploy:
	@echo About to deploy a few sample projects to OpenShift
	./hack/openshift-deploy.sh -n kiali-test-depth -c hack/test-configs/test-depth.yaml
	./hack/openshift-deploy.sh -n kiali-test-breadth -c hack/test-configs/test-breadth.yaml
	./hack/openshift-deploy.sh -n kiali-test-hourglass -c hack/test-configs/test-hourglass.yaml
	./hack/openshift-deploy.sh -n kiali-test-circle-callback -c hack/test-configs/test-circle-callback.yaml
