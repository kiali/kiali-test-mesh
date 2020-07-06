KIALI_TEST_MESH_OPERATOR_NAMESPACE ?= kiali-test-mesh-operator
BOOKINFO_NAMESPACE ?= bookinfo
BOOKINFO_HUB ?= docker.io/istio
BOOKINFO_VERSION ?= 1.15.0
BOOKINFO_MYSQL ?= true
BOOKINFO_MONGODB ?= true
CONTROL_PLANE_NAMESPACE ?= istio-system
REDHAT_TUTORIAL_NAMESPACE ?= redhat-istio-tutorial
OPERATOR_IMAGE ?= quay.io/kiali/kiali-test-mesh-operator:testing
KIALI_TEST_MESH_LABEL ?= kiali-test-mesh-operator=owned
ENABLE_MULTI_TENANT ?= true

SCALE_MESH_NUMBER_SERVICES ?=5
SCALE_MESH_NUMBER_APPS ?=5
SCALE_MESH_NUMBER_VERSIONS ?=2
SCALE_MESH_NUMBER_NAMESPACES ?=1
SCALE_MESH_TYPE ?= mesh-circle

build-operator-image:
	@echo Building operator
	cd operator && operator-sdk build ${OPERATOR_IMAGE}

push-operator-image:
	@echo Push Operator image
	docker push ${OPERATOR_IMAGE}

deploy-operator: remove-operator
	@echo Deploy Kiali Tesh Mesh Operator on Openshift
	oc new-project ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc label namespace ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} ${KIALI_TEST_MESH_LABEL}
	oc adm policy add-scc-to-user privileged -z default -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc create -f operator/deploy/scale_mesh-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc create -f operator/deploy/redhat_tutorial-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc create -f operator/deploy/bookinfo-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc create -f operator/deploy/service_account.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc create -f operator/deploy/role_binding.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	cat operator/deploy/operator.yaml | IMAGE=${OPERATOR_IMAGE} envsubst | oc create -f - -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 

remove-operator:
	@echo Remove Kiali Test Mesh Operator on Openshift
	oc delete --ignore-not-found=true -f operator/deploy/scale_mesh-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc delete --ignore-not-found=true -f operator/deploy/redhat_tutorial-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} 
	oc delete --ignore-not-found=true -f operator/deploy/bookinfo-crd.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc delete --ignore-not-found=true -f operator/deploy/service_account.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc delete --ignore-not-found=true -f operator/deploy/role_binding.yaml -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	cat operator/deploy/operator.yaml | IMAGE=${OPERATOR_IMAGE} envsubst | oc delete --ignore-not-found=true -f - -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}
	oc delete namespace ${KIALI_TEST_MESH_OPERATOR_NAMESPACE} --ignore-not-found=true


deploy-cr-redhat-istio-tutorial:
	@echo Create Red Hat Istio Tutorial CR
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE}  envsubst | oc apply -f - -n ${REDHAT_TUTORIAL_NAMESPACE} 

create-redhat-istio-tutorial-namespace:
	oc new-project ${REDHAT_TUTORIAL_NAMESPACE}
	oc label namespace ${REDHAT_TUTORIAL_NAMESPACE} ${KIALI_TEST_MESH_LABEL}

remove-redhat-istio-tutorial-cr:
	@echo Remove Red Hat Istio Tutorial CR
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE}  envsubst | oc delete -f - -n ${REDHAT_TUTORIAL_NAMESPACE} --ignore-not-found=true 

remove-redhat-istio-tutorial-namespace:
	@echo Remove Red Hat Istio Tutorial Namespace
	oc delete --ignore-not-found=true namespace ${REDHAT_TUTORIAL_NAMESPACE}


create-bookinfo-namespace:
	oc new-project ${BOOKINFO_NAMESPACE}
	oc label namespace ${BOOKINFO_NAMESPACE} ${KIALI_TEST_MESH_LABEL}
	oc adm policy add-scc-to-user privileged -z default -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${BOOKINFO_NAMESPACE}

deploy-cr-bookinfo:
	cat operator/deploy/cr/bookinfo-cr.yaml | BOOKINFO_NAMESPACE=${BOOKINFO_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} BOOKINFO_HUB=${BOOKINFO_HUB}  envsubst | oc apply -f - -n ${BOOKINFO_NAMESPACE} 

remove-bookinfo-namespace:
	@echo Remove Bookinfo Namespace
	oc delete --ignore-not-found=true namespace ${BOOKINFO_NAMESPACE}

remove-bookinfo-cr:
	@echo Remove Bookinfo CR on Openshift
	cat operator/deploy/cr/bookinfo-cr.yaml | BOOKINFO_NAMESPACE=${BOOKINFO_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE}   envsubst | oc delete -f - -n ${BOOKINFO_NAMESPACE}  --ignore-not-found=true

deploy-scale-mesh: 
	cat operator/deploy/cr/scale_mesh-cr.yaml | CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} CONTROL_PLANE_NAME=${CONTROL_PLANE_NAME} SCALE_MESH_NUMBER_SERVICES=${SCALE_MESH_NUMBER_SERVICES} SCALE_MESH_NUMBER_VERSIONS=${SCALE_MESH_NUMBER_VERSIONS} SCALE_MESH_NUMBER_NAMESPACES=${SCALE_MESH_NUMBER_NAMESPACES} SCALE_MESH_TYPE=${SCALE_MESH_TYPE} SCALE_MESH_NUMBER_APPS=${SCALE_MESH_NUMBER_APPS} envsubst | oc apply -f - -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}

remove-scale-mesh:
	cat operator/deploy/cr/scale_mesh-cr.yaml | CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} CONTROL_PLANE_NAME=${CONTROL_PLANE_NAME} SCALE_MESH_NUMBER_SERVICES=${SCALE_MESH_NUMBER_SERVICES} SCALE_MESH_NUMBER_VERSIONS=${SCALE_MESH_NUMBER_VERSIONS} SCALE_MESH_NUMBER_NAMESPACES=${SCALE_MESH_NUMBER_NAMESPACES} SCALE_MESH_TYPE=${SCALE_MESH_TYPE} SCALE_MESH_NUMBER_APPS=${SCALE_MESH_NUMBER_APPS} envsubst | oc delete -f - -n ${KIALI_TEST_MESH_OPERATOR_NAMESPACE}

add-bookinfo-control-plane: 
ifeq ($(ENABLE_MULTI_TENANT),true) 
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": "/spec/members/0", "value":"${BOOKINFO_NAMESPACE}"}]'
endif


deploy-bookinfo: remove-bookinfo-cr remove-bookinfo-namespace create-bookinfo-namespace add-bookinfo-control-plane deploy-cr-bookinfo
	@echo Deployed Bookinfo

deploy-redhat-istio-tutorial: remove-redhat-istio-tutorial-cr remove-redhat-istio-tutorial-namespace create-redhat-istio-tutorial-namespace deploy-cr-redhat-istio-tutorial
	@echo Deployed Red Hat Istio Tutorial

deploy-bookinfo-playbook: remove-bookinfo-namespace create-bookinfo-namespace add-bookinfo-control-plane
	ansible-playbook operator/bookinfo.yml -e '{"bookinfo": {"namespace": "${BOOKINFO_NAMESPACE}", "control_plane_namespace": "${CONTROL_PLANE_NAMESPACE}", "mongodb": false, "mysql": true, "version": "1.14.0"}}' -v