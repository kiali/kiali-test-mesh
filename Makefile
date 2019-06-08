KIALI_TEST_MESH_OPERATOR_NAMESPACE ?= kiali-test-mesh-operator
BOOKINFO_NAMESPACE ?= bookinfo
CONTROL_PLANE_NAMESPACE ?= istio-system
REDHAT_TUTORIAL_NAMESPACE ?= redhat-istio-tutorial


OPERATOR_IMAGE ?= gbaufake/kiali-test-mesh-operator:refactor-traffic-generator

SECRET_PATH ?= operator/deploy/secret.yaml
SECRET_NAME ?= pull_secret

MANUAL_INJECTION_SIDECAR ?= false
MULTI_TENANCY ?= true
ENABLE_SECRET ?= true

build-operator-image:
	@echo Building operator
	cd operator && operator-sdk build ${OPERATOR_IMAGE}

push-operator-image:
	@echo Building Push image
	docker push ${OPERATOR_IMAGE}

deploy-operator: remove-operator
	@echo Deploy Kiali Tesh Mesh Operator on Openshift
	oc create namespace ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc label namespace ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} kiali-test-mesh-operator=owned
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


deploy-redhat-istio-tutorial: remove-redhat-istio-tutorial-cr remove-redhat-istio-tutorial-namespace create-redhat-istio-tutorial-namespace add-redhat-istio-tutorial-control-plane cr-redhat-istio-tutorial
	@echo Deployed Red Hat Istio Tutorial	

cr-redhat-istio-tutorial:
	@echo Create Red Hat Istio Tutorial CR
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | REDHAT_TUTORIAL_NAMESPACE=${REDHAT_TUTORIAL_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc apply -f - -n kiali-test-mesh-operator 


add-redhat-istio-tutorial-to-control-plane:
ifeq ($(MULTI_TENANCY),true)
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": /spec/members/0, "value":"${REDHAT_TUTORIAL_NAMESPACE}"}]'
endif

quay-secret-redhat-istio-tutorial:
ifeq ($(ENABLE_SECRET), true)
	oc apply -f ${SECRET_PATH} -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc adm policy add-scc-to-user privileged -z default -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc secrets link deployer ${SECRET_NAME} --for=pull -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc secrets link deployer ${SECRET_NAME} --for=pull -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc secrets link default ${SECRET_NAME} --for=pull -n ${REDHAT_TUTORIAL_NAMESPACE}
endif

create-redhat-istio-tutorial-namespace:
	oc create namespace ${REDHAT_TUTORIAL_NAMESPACE}
	oc label namespace ${REDHAT_TUTORIAL_NAMESPACE} kiali-test-mesh-operator=owned
	oc adm policy add-scc-to-user privileged -z default -n ${REDHAT_TUTORIAL_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${REDHAT_TUTORIAL_NAMESPACE}

remove-redhat-istio-tutorial-cr:
	@echo Remove Red Hat Istio Tutorial CR
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | REDHAT_TUTORIAL_NAMESPACE=${REDHAT_TUTORIAL_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc delete -f - -n kiali-test-mesh-operator --ignore-not-found=true 

remove-redhat-istio-tutorial-namespace:
	@echo Remove Red Hat Istio Tutorial Namespace
	oc delete --ignore-not-found=true namespace ${REDHAT_TUTORIAL_NAMESPACE}

deploy-redhat-istio-tutorial-playbook: remove-redhat-istio-tutorial-namespace create-redhat-istio-tutorial-namespace quay-secret-redhat-istio-tutorial add-redhat-istio-tutorial-control-plane
	ansible-playbook operator/redhat_istio_tutorial.yml -e '{"redhat_tutorial": {"namespace": "${REDHAT_TUTORIAL_NAMESPACE}", "control_plane_namespace": "${CONTROL_PLANE_NAMESPACE}"}}' -v

quay-secret-bookinfo:
ifeq ($(ENABLE_SECRET), true)
	oc apply -f ${SECRET_PATH} -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user privileged -z default -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${BOOKINFO_NAMESPACE}
	oc secrets link deployer ${SECRET_NAME} --for=pull -n ${BOOKINFO_NAMESPACE}
	oc secrets link deployer ${SECRET_NAME} --for=pull -n ${BOOKINFO_NAMESPACE}
	oc secrets link default ${SECRET_NAME} --for=pull -n ${BOOKINFO_NAMESPACE}
endif

create-bookinfo-namespace:
	oc create namespace ${BOOKINFO_NAMESPACE}
	oc label namespace ${BOOKINFO_NAMESPACE} kiali-test-mesh-operator=owned
	oc adm policy add-scc-to-user privileged -z default -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${BOOKINFO_NAMESPACE}

add-bookinfo-to-control-plane:
ifeq ($(MULTI_TENANCY),true) 
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": /spec/members/0, "value":"${BOOKINFO_NAMESPACE}"}]'
endif

cr-bookinfo:
	cat operator/deploy/cr/bookinfo-cr.yaml | BOOKINFO_NAMESPACE=${BOOKINFO_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE}  envsubst | oc apply -f - -n ${BOOKINFO_NAMESPACE} 

remove-bookinfo-namespace:
	@echo Remove Bookinfo Namespace
	oc delete --ignore-not-found=true namespace ${BOOKINFO_NAMESPACE}

remove-bookinfo-cr:
	@echo Remove Bookinfo CR on Openshift
	cat operator/deploy/cr/bookinfo-cr.yaml | BOOKINFO_NAMESPACE=${BOOKINFO_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE}  envsubst | oc delete -f - -n ${BOOKINFO_NAMESPACE}  --ignore-not-found=true

deploy-bookinfo: remove-bookinfo-cr remove-bookinfo-namespace create-bookinfo-namespace quay-secret-bookinfo add-bookinfo-to-control-plane cr-bookinfo

deploy-bookinfo-playbook: remove-bookinfo-namespace create-bookinfo-namespace quay-secret-bookinfo add-bookinfo-control-plane
	ansible-playbook operator/bookinfo.yml -e '{"bookinfo": {"namespace": "${BOOKINFO_NAMESPACE}", "control_plane_namespace": "${CONTROL_PLANE_NAMESPACE}", "mongodb": "true", "mysql": "true", "version": "1.14.0"}}' -v


# deploy-complex-mesh-manual-sidecar:
# 	@echo Deploy Complex Mesh with Manual Injection
# 	oc create namespace kiali-test-frontend
# 	oc create namespace kiali-test-reviews
# 	oc create namespace kiali-test-ratings

# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-frontend
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-frontend
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-reviews
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-reviews
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-ratings
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-ratings
# 	oc create -f operator/deploy/cr/manual-sidecar/complex_mesh-cr.yaml -n kiali-test-frontend

# deploy-complex-mesh-automatic-sidecar:
# 	@echo Deploy Complex Mesh
# 	oc create namespace kiali-test-frontend
# 	oc create namespace kiali-test-reviews
# 	oc create namespace kiali-test-ratings

# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-frontend
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-frontend
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-reviews
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-reviews
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-ratings
# 	oc adm policy add-scc-to-user anyuid -z default -n kiali-test-ratings
# 	oc create -f operator/deploy/cr/automatic-sidecar/complex_mesh-cr.yaml -n kiali-test-frontend
