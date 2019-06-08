BOOKINFO_NAMESPACE ?= bookinfo
CONTROL_PLANE_NAMESPACE ?= istio-system
MULTI_TENANCY ?= true
REDHAT_TUTORIAL ?= redhat-istio-tutorial
OPERATOR_IMAGE ?= gbaufake/kiali-test-mesh-operator:refactor-traffic-generator
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


deploy-redhat-istio-tutorial: remove-redhat-istio-tutorial-cr remove-redhat-istio-tutorial-namespace create-redhat-istio-tutorial-namespace add-redhat-istio-tutorial-control-plane cr-redhat-istio-tutorial
	@echo Deployed Red Hat Istio Tutorial	

cr-redhat-istio-tutorial:
	@echo Create Red Hat Istio Tutorial CR
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | REDHAT_TUTORIAL=${REDHAT_TUTORIAL} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc apply -f - -n kiali-test-mesh-operator 


add-redhat-istio-tutorial-control-plane:
ifeq ($(MULTI_TENANCY),true)
	oc patch servicemeshmemberroll default -n ${CONTROL_PLANE_NAMESPACE} --type='json' -p='[{"op": "add", "path": /spec/members/0, "value":"${REDHAT_TUTORIAL}"}]'
endif

create-redhat-istio-tutorial-namespace:
	oc create namespace ${REDHAT_TUTORIAL}
	oc adm policy add-scc-to-user privileged -z default -n ${REDHAT_TUTORIAL}
	oc adm policy add-scc-to-user anyuid -z default -n ${REDHAT_TUTORIAL}

remove-redhat-istio-tutorial-cr:
	@echo Remove Red Hat Istio Tutorial CR
	cat operator/deploy/cr/redhat_tutorial-cr.yaml | REDHAT_TUTORIAL=${REDHAT_TUTORIAL} CONTROL_PLANE_NAMESPACE=${CONTROL_PLANE_NAMESPACE} MANUAL_INJECTION_SIDECAR=${MANUAL_INJECTION_SIDECAR} envsubst | oc delete -f - -n kiali-test-mesh-operator --ignore-not-found=true 

remove-redhat-istio-tutorial-namespace:
	@echo Remove Red Hat Istio Tutorial Namespace
	oc delete --ignore-not-found=true namespace ${REDHAT_TUTORIAL}

deploy-redhat-istio-tutorial-playbook: remove-redhat-istio-tutorial-namespace create-redhat-istio-tutorial-namespace secret-workaround-redhat-istio-tutorial add-redhat-istio-tutorial-control-plane
	ansible-playbook operator/redhat_istio_tutorial.yml -e '{"redhat_tutorial": {"namespace": "${REDHAT_TUTORIAL}", "control_plane_namespace": "${CONTROL_PLANE_NAMESPACE}"}}' -v

create-bookinfo-namespace:
	oc create namespace ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user privileged -z default -n ${BOOKINFO_NAMESPACE}
	oc adm policy add-scc-to-user anyuid -z default -n ${BOOKINFO_NAMESPACE}

add-bookinfo-control-plane:
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

deploy-bookinfo: remove-bookinfo-cr remove-bookinfo-namespace create-bookinfo-namespace secret-workaround-bookinfo add-bookinfo-control-plane cr-bookinfo

deploy-bookinfo-playbook: remove-bookinfo-namespace create-bookinfo-namespace secret-workaround-bookinfo add-bookinfo-control-plane
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
