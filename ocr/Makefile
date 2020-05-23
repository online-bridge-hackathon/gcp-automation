GCP_PROJECT ?= online-bridge-hackathon-2020
GCP_REGION ?= europe-west1
GCP_ZONE ?= europe-west1-b
GCP_NETWORK ?= default
GCP_SUBNETWORK ?= default
VM_NAME ?= ocr-vm

GCP_STATE_BUCKET ?= hackathon-tfstate

ROOT_DIR=$(shell pwd)
TERRAFORM_ROOT_DIR=${ROOT_DIR}/terraform
TMP_DIR=${ROOT_DIR}/.tmp

TERRAFORM_OUTPUT = ${TMP_DIR}/terraform.output

define CREATE_CLUSTER_TF_VARS
-var "project_id=${GCP_PROJECT}" \
-var "network=${GCP_NETWORK}" \
-var "subnetwork=${GCP_SUBNETWORK}" \
-var "region=${GCP_REGION}" \
-var "zone=${GCP_ZONE}" \
-var "vm_name=${VM_NAME}"
endef

set_gcp_project:
	set -e

	gcloud config set project ${GCP_PROJECT}

provision: set_gcp_project
	set -e

	cd ${TERRAFORM_ROOT_DIR} && \
		terraform init -no-color -backend-config="bucket=${GCP_STATE_BUCKET}" -backend-config="prefix=ocr/${VM_NAME}" && \
		terraform plan -no-color --out ${TMP_DIR}/${VM_NAME}.provision.plan ${CREATE_CLUSTER_TF_VARS} && \
		terraform apply -no-color ${TMP_DIR}/${VM_NAME}.provision.plan && \
		terraform output -no-color --json > ${TERRAFORM_OUTPUT}

deprovision: set_gcp_project
	set -e

	cd ${TERRAFORM_ROOT_DIR} && \
		terraform init -no-color -backend-config="bucket=${GCP_STATE_BUCKET}" -backend-config="prefix=ocr/${VM_NAME}" && \
		terraform plan -no-color -destroy --out ${TMP_DIR}/${GKE_CLUSTER_NAME}.deprovision.plan ${CREATE_CLUSTER_TF_VARS} && \
		terraform apply -no-color ${TMP_DIR}/${VM_NAME}.deprovision.plan
