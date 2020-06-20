GCP_PROJECT ?= online-bridge-hackathon-2020
GKE_CLUSTER_NAME ?= hackathon-cluster
GKE_NODE_COUNT ?= 4
GCP_REGION ?= europe-west3
GCP_ZONE ?= europe-west3-b
GCP_NETWORK ?= default
GCP_SUBNETWORK ?= default
MASTER_IPV4_CIDR_BLOCK ?= 172.16.0.16/28

GCP_STATE_BUCKET ?= hackathon-tfstate

ROOT_DIR=$(shell pwd)
TERRAFORM_ROOT_DIR=${ROOT_DIR}/terraform
MANIFESTS_DIR=${ROOT_DIR}/manifests
TMP_DIR=${ROOT_DIR}/.tmp

TERRAFORM_OUTPUT = ${TMP_DIR}/terraform.output

define CREATE_CLUSTER_TF_VARS
-var "project_id=${GCP_PROJECT}" \
-var "cluster_name=${GKE_CLUSTER_NAME}" \
-var "region=${GCP_REGION}" \
-var "cluster_location=${GCP_ZONE}" \
-var "cluster_node_count=${GKE_NODE_COUNT}" \
-var "network=${GCP_NETWORK}" \
-var "subnetwork=${GCP_SUBNETWORK}" \
-var "master_ipv4_cidr_block=${MASTER_IPV4_CIDR_BLOCK}" \
-var "machine_type=${MACHINE_TYPE}"
endef

set_gcp_project:
	set -e

	mkdir -p ${PWD}/.tmp
	gcloud config set project ${GCP_PROJECT}

set_cluster_context:
	set -e

	gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --zone ${GCP_ZONE}

provision: set_gcp_project
	set -e

	cd ${TERRAFORM_ROOT_DIR} && \
		terraform init -no-color -backend-config="bucket=${GCP_STATE_BUCKET}" -backend-config="prefix=gke/${GKE_CLUSTER_NAME}" && \
		terraform plan -no-color --out ${TMP_DIR}/${GKE_CLUSTER_NAME}.provision.plan ${CREATE_CLUSTER_TF_VARS} && \
		terraform apply -no-color ${TMP_DIR}/${GKE_CLUSTER_NAME}.provision.plan && \
		terraform output -no-color --json > ${TERRAFORM_OUTPUT}

deprovision: set_gcp_project
	set -e

	cd ${TERRAFORM_ROOT_DIR} && \
		terraform init -no-color -backend-config="bucket=${GCP_STATE_BUCKET}" -backend-config="prefix=gke/${GKE_CLUSTER_NAME}" && \
		terraform plan -no-color -destroy --out ${TMP_DIR}/${GKE_CLUSTER_NAME}.deprovision.plan ${CREATE_CLUSTER_TF_VARS} && \
		terraform apply -no-color ${TMP_DIR}/${GKE_CLUSTER_NAME}.deprovision.plan

prepare_cluster: set_gcp_project set_cluster_context _install_nginx_ingress _install_cert_manager

_install_nginx_ingress:
	set -e

	# @Sarguel suggest these two lines are added
	helm repo add stable https://kubernetes-charts.storage.googleapis.com/
	helm repo update

	$(eval ingress_ip := ${shell cat ${TERRAFORM_OUTPUT} | jq -r .ingress_ip.value.address})
	kubectl create ns nginx-ingress || :
	helm upgrade --install nginx-ingress stable/nginx-ingress --namespace nginx-ingress --version 0.30.0 --set controller.service.loadBalancerIP=${ingress_ip}

_install_cert_manager:
	set -e

	helm repo add jetstack https://charts.jetstack.io
	helm repo update

	kubectl apply -f ${MANIFESTS_DIR}/cert-manager-legacy.crds.yaml

	kubectl create ns cert-manager || :
	helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --version v0.14.2

	kubectl rollout status deployment/cert-manager-webhook -n cert-manager

	kubectl apply -f ${MANIFESTS_DIR}/cert-manager-ci.prod.yaml
	kubectl apply -f ${MANIFESTS_DIR}/cert-manager-ci.staging.yaml
