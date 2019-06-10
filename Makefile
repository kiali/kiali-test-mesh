KIALI_TEST_MESH_OPERATOR_NAMESPACE ?= kiali-test-mesh-operator
BOOKINFO_NAMESPACE ?= bookinfo
CONTROL_PLANE_NAMESPACE ?= istio-system
REDHAT_TUTORIAL_NAMESPACE ?= redhat-istio-tutorial
OPERATOR_IMAGE ?= kiali/kiali-test-mesh-operator:latest
SECRET_PATH ?= operator/deploy/secret.yaml
SECRET_NAME ?= pull-secret
KIALI_TEST_MESH_LABEL ?= kiali-test-mesh-operator=owned
MANUAL_INJECTION_SIDECAR ?= false
ENABLE_SECRET ?= false
ENABLE_MULTI_TENANT ?= false

build-operator-image:
	@echo Building operator
	cd operator && operator-sdk build ${OPERATOR_IMAGE}

push-operator-image:
	@echo Building Push image
	docker push ${OPERATOR_IMAGE}

deploy-operator: remove-operator
	@echo Deploy Kiali Tesh Mesh Operator on Openshift
	oc create namespace ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc label namespace ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} ${KIALI_TEST_MESH_LABEL}
	oc create -f operator/deploy/redhat_tutorial-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc create -f operator/deploy/bookinfo-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc create -f operator/deploy/complex_mesh-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc create -f operator/deploy/service_account.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc create -f operator/deploy/role_binding.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	cat operator/deploy/operator.yaml | IMAGE=${OPERATOR_IMAGE} envsubst | oc create -f - -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 


remove-operator:
	@echo Remove Kiali Test Mesh Operator on Openshift
	oc delete --ignore-not-found=true -f operator/deploy/redhat_tutorial-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc delete --ignore-not-found=true -f operator/deploy/bookinfo-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc delete --ignore-not-found=true -f operator/deploy/complex_mesh-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc delete --ignore-not-found=true -f operator/deploy/service_account.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc delete --ignore-not-found=true -f operator/deploy/role_binding.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	cat operator/deploy/operator.yaml | IMAGE=${OPERATOR_IMAGE} envsubst | oc delete --ignore-not-found=true -f - -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc delete namespace ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} --ignore-not-found=true


deploy-cr-redhat-istio-tutorial:
	@echo Create Red Hat Istio Tutorial CR
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | REDHAT_TUTORIAL_NAMESPACE=${REDHAT_TUTORIAL_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc apply -f - -n kiali-test-mesh-operator 

create-redhat-istio-tutorial-namespace:
	oc create namespace ${REDHAT_TUTORIAL_NAMESPACE}
	oc label namespace ${REDHAT_TUTORIAL_NAMESPACE} ${KIALI_TEST_MESH_LABEL}
	oc adm policy add-scc-to-user privileged -z default -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${REDHAT_TUTORIAL_NAMESPACE}

remove-redhat-istio-tutorial-cr:
	@echo Remove Red Hat Istio Tutorial CR
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | REDHAT_TUTORIAL_NAMESPACE=${REDHAT_TUTORIAL_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc delete -f - -n kiali-test-mesh-operator --ignore-not-found=true 

remove-redhat-istio-tutorial-namespace:
	@echo Remove Red Hat Istio Tutorial Namespace
	oc delete --ignore-not-found=true namespace ${REDHAT_TUTORIAL_NAMESPACE}



create-bookinfo-namespace:
	oc create namespace ${BOOKINFO_NAMESPACE}
	oc label namespace ${BOOKINFO_NAMESPACE} ${KIALI_TEST_MESH_LABEL}
	oc adm policy add-scc-to-user privileged -z default -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${BOOKINFO_NAMESPACE}

deploy-cr-bookinfo:
	cat operator/deploy/cr/bookinfo-cr.yaml | BOOKINFO_NAMESPACE=${BOOKINFO_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc apply -f - -n ${BOOKINFO_NAMESPACE} 

remove-bookinfo-namespace:
	@echo Remove Bookinfo Namespace
	oc delete --ignore-not-found=true namespace ${BOOKINFO_NAMESPACE}

remove-bookinfo-cr:
	@echo Remove Bookinfo CR on Openshift
	cat operator/deploy/cr/bookinfo-cr.yaml | BOOKINFO_NAMESPACE=${BOOKINFO_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE}  envsubst | oc delete -f - -n ${BOOKINFO_NAMESPACE}  --ignore-not-found=true

quay-secret-bookinfo:
ifeq ($(ENABLE_SECRET), true)
	oc apply -f ${SECRET_PATH} -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user privileged -z default -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${BOOKINFO_NAMESPACE}
	oc secrets link deployer ${SECRET_NAME} --for=pull -n ${BOOKINFO_NAMESPACE}
	oc secrets link default ${SECRET_NAME} --for=pull -n ${BOOKINFO_NAMESPACE}
endif

quay-secret-complex-mesh:
ifeq ($(ENABLE_SECRET), true)
	oc apply -f ${SECRET_PATH} -n kiali-test-frontend 
	oc adm policy add-scc-to-user privileged -z default -n kiali-test-frontend 
	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-frontend 
	oc secrets link deployer ${SECRET_NAME} --for=pull -n kiali-test-frontend 
	oc secrets link default ${SECRET_NAME} --for=pull -n kiali-test-frontend 

	oc apply -f ${SECRET_PATH} -n kiali-test-reviews 
	oc adm policy add-scc-to-user privileged -z default -n kiali-test-reviews 
	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-reviews 
	oc secrets link deployer ${SECRET_NAME} --for=pull -n kiali-test-reviews 
	oc secrets link default ${SECRET_NAME} --for=pull -n kiali-test-reviews 

	oc apply -f ${SECRET_PATH} -n kiali-test-ratings 
	oc adm policy add-scc-to-user privileged -z default -n kiali-test-ratings 
	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-ratings 
	oc secrets link deployer ${SECRET_NAME} --for=pull -n kiali-test-ratings 
	oc secrets link default ${SECRET_NAME} --for=pull -n kiali-test-ratings 
endif

quay-secret-redhat-istio-tutorial:
ifeq ($(ENABLE_SECRET), true)
	oc apply -f ${SECRET_PATH} -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc adm policy add-scc-to-user privileged -z default -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc secrets link deployer ${SECRET_NAME} --for=pull -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc secrets link default ${SECRET_NAME} --for=pull -n ${REDHAT_TUTORIAL_NAMESPACE}
endif

create-complex-mesh-namespace:
	@echo Create Complex Mesh Namespaces
	oc create namespace kiali-test-frontend 
	oc label namespace  kiali-test-frontend ${KIALI_TEST_MESH_LABEL}
	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-frontend 
	oc adm policy add-scc-to-user privileged -z default -n kiali-test-frontend
	oc create namespace kiali-test-reviews 
	oc label namespace  kiali-test-reviews ${KIALI_TEST_MESH_LABEL}
	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-reviews 
	oc adm policy add-scc-to-user privileged -z default -n kiali-test-reviews
	oc create namespace kiali-test-ratings 
	oc label namespace  kiali-test-ratings ${KIALI_TEST_MESH_LABEL}
	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-ratings 
	oc adm policy add-scc-to-user privileged -z default -n kiali-test-ratings

		
remove-complex-mesh-namespace:
	@echo Remove Complex Namespaces
	oc delete namespace --ignore-not-found kiali-test-frontend
	oc delete namespace --ignore-not-found kiali-test-ratings
	oc delete namespace --ignore-not-found kiali-test-reviews


deploy-cr-complex-mesh: 
	cat operator/deploy/cr/complex_mesh-cr.yaml | MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc apply -f - -n kiali-test-frontend 

remove-cr-complex-mesh-cr: 
	cat operator/deploy/cr/complex_mesh-cr.yaml | MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc delete -f - -n kiali-test-frontend


test2: add-bookinfo-control-plane add-complex-mesh-control-plane add-redhat-istio-tutorial-control-plane

add-bookinfo-control-plane: 
ifeq ($(ENABLE_MULTI_TENANT),true) 
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": "/spec/members/0", "value":"${BOOKINFO_NAMESPACE}"}]'
endif

add-complex-mesh-control-plane:
ifeq ($(ENABLE_MULTI_TENANT), true) 
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": "/spec/members/0", "value": "kiali-test-frontend"}]'
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": "/spec/members/0", "value": "kiali-test-reviews"}]'
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": "/spec/members/0", "value": "kiali-test-ratings"}]'
endif

add-redhat-istio-tutorial-control-plane:
ifeq ($(ENABLE_MULTI_TENANT), true)
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": "/spec/members/0", "value":"${REDHAT_TUTORIAL_NAMESPACE}"}]'
endif

deploy-bookinfo: remove-bookinfo-cr remove-bookinfo-namespace create-bookinfo-namespace quay-secret-bookinfo add-bookinfo-control-plane deploy-cr-bookinfo
	@echo Deployed Bookinfo

deploy-redhat-istio-tutorial: remove-redhat-istio-tutorial-cr remove-redhat-istio-tutorial-namespace create-redhat-istio-tutorial-namespace add-redhat-istio-tutorial-control-plane deploy-cr-redhat-istio-tutorial
	@echo Deployed Red Hat Istio Tutorial

deploy-complex-mesh: remove-complex-mesh-cr remove-complex-mesh-namespace create-complex-mesh-namespace add-complex-mesh-control-plane deploy-cr-complex-mesh
	@echo Deployed Complex Mesh

deploy-redhat-istio-tutorial-playbook: remove-redhat-istio-tutorial-namespace create-redhat-istio-tutorial-namespace quay-secret-redhat-istio-tutorial 
	ansible-playbook operator/redhat_istio_tutorial.yml -e '{"redhat_tutorial": {"namespace": "${REDHAT_TUTORIAL_NAMESPACE}", "control_plane_namespace": "${CONTROL_PLANE_NAMESPACE}"}}' -v

deploy-bookinfo-playbook: remove-bookinfo-namespace create-bookinfo-namespace quay-secret-bookinfo add-bookinfo-control-plane
	ansible-playbook operator/bookinfo.yml -e '{"bookinfo": {"namespace": "${BOOKINFO_NAMESPACE}", "control_plane_namespace": "${CONTROL_PLANE_NAMESPACE}", "mongodb": "true", "mysql": "true", "version": "1.14.0"}}' -v

deploy-complex-playbook:
	ansible-playbook operator/complex_mesh.yml  -v