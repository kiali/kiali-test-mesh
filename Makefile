BOOKINFO_NAMESPACE ?= bookinfo3
CONTROL_PLANE_NAMESPACE ?= istio-system
REDHAT_TUTORIAL ?= redhat-istio-tutorial
OPERATOR_IMAGE ?= gbaufake/kiali-test-mesh-operator:refactor
MANUAL_INJECTION_SIDECAR ?= false

build-operator-image:
	@echo Building operator
	cd operator && operator-sdk build ${OPERATOR_IMAGE}

push-operator-image:
	@echo Building Push image
	docker push ${OPERATOR_IMAGE}

deploy-operator: remove-operator
	@echo Deploy Kiali Tesh Mesh Operator on Openshift
	oc new-project kiali-test-mesh-operator
	oc create -f operator/deploy/redhat_tutorial-crd.yaml -n kiali-test-mesh-operator 
	oc create -f operator/deploy/bookinfo-crd.yaml -n kiali-test-mesh-operator 
	oc create -f operator/deploy/complex_mesh-crd.yaml -n kiali-test-mesh-operator
	oc create -f operator/deploy/service_account.yaml -n kiali-test-mesh-operator 
	oc create -f operator/deploy/role_binding.yaml -n kiali-test-mesh-operator
	cat operator/deploy/operator.yaml | IMAGE=${OPERATOR_IMAGE} envsubst | oc create -f - -n kiali-test-mesh-operator 


remove-operator:
	@echo Remove Kiali Test Mesh Operator on Openshift
	oc delete --ignore-not-found=true -f operator/deploy/redhat_tutorial-crd.yaml -n kiali-test-mesh-operator 
	oc delete --ignore-not-found=true -f operator/deploy/bookinfo-crd.yaml -n kiali-test-mesh-operator
	oc delete --ignore-not-found=true -f operator/deploy/complex_mesh-crd.yaml -n kiali-test-mesh-operator
	oc delete --ignore-not-found=true -f operator/deploy/service_account.yaml -n kiali-test-mesh-operator
	oc delete --ignore-not-found=true -f operator/deploy/role_binding.yaml -n kiali-test-mesh-operator
	cat operator/deploy/operator.yaml | IMAGE=${OPERATOR_IMAGE} envsubst | oc delete --ignore-not-found=true -f - -n kiali-test-mesh-operator
	oc delete namespace kiali-test-mesh-operator --ignore-not-found=true


deploy-redhatutorial: remove-redhatutorial
	@echo Deploy Red Hat Istio Tutorial with Automatic Injection of the sidecar on Openshift
	oc create namespace ${REDHAT_TUTORIAL}
	oc adm policy add-scc-to-user privileged -z default -n ${REDHAT_TUTORIAL}
	oc adm policy add-scc-to-user anyuid -z default -n ${REDHAT_TUTORIAL}
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | REDHAT_TUTORIAL=${REDHAT_TUTORIAL} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc apply -f - -n kiali-test-mesh-operator 

remove-redhatutorial:
	@echo Remove Red Hat Istio Tutorial with Automatic Injection of the sidecar on Openshift
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | REDHAT_TUTORIAL=${REDHAT_TUTORIAL} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc delete -f - -n kiali-test-mesh-operator --ignore-not-found=true 
	oc delete --ignore-not-found=true namespace ${REDHAT_TUTORIAL}



deploy-bookinfo: remove-bookinfo
	@echo Deploy Bookinfo with Automatic Injection of the sidecar on Openshift
	oc create namespace ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user privileged -z default -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${BOOKINFO_NAMESPACE}
	cat operator/deploy/cr/bookinfo-cr.yaml | BOOKINFO_NAMESPACE=${BOOKINFO_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE}  envsubst | oc apply -f - -n ${BOOKINFO_NAMESPACE} 

# deploy-complex-mesh-manual-sidecar:
# 	@echo Deploy Complex Mesh with Manual Injection of the sidecar on Openshift
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
# 	@echo Deploy Complex Mesh with Automatic Injection of the sidecar on Openshift
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


remove-bookinfo:
	@echo Remove Bookinfo on Openshift
	cat operator/deploy/cr/bookinfo-cr.yaml | BOOKINFO_NAMESPACE=${BOOKINFO_NAMESPACE} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE}  envsubst | oc delete -f - -n ${BOOKINFO_NAMESPACE}  --ignore-not-found=true
	oc delete --ignore-not-found=true namespace ${BOOKINFO_NAMESPACE}