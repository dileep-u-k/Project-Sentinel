#!/bin/bash

# ==============================================================================
# Project Sentinel: Infrastructure Management CLI (V2.3)
#
# Description:
#   This script acts as a CLI tool to manage the full lifecycle of the
#   local Kubernetes development environment and its core services.
#   V2.3 fixes incorrect relative file paths for cluster configs.
# ==============================================================================

# --- Script Setup ---
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "$0")/env.sh" || exit 1

# --- Helper Functions for Colored Output ---
print_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1" >&2; }

# --- Prerequisite Check ---
check_dependencies() {
    print_info "Checking for required dependencies (k3d, kubectl, helm)..."
    command -v k3d >/dev/null 2>&1 || { print_error "k3d is not installed."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { print_error "kubectl is not installed."; exit 1; }
    command -v helm >/dev/null 2>&1 || { print_error "helm is not installed."; exit 1; }
    print_success "All dependencies are installed."
}

# --- Cluster Management Functions ---
create_cluster() {
    if ! k3d cluster get "${SENTINEL_CLUSTER_NAME}" >/dev/null 2>&1; then
        print_info "Creating ${SENTINEL_SERVER_COUNT}-server, ${SENTINEL_AGENT_COUNT}-agent k3d cluster named '${SENTINEL_CLUSTER_NAME}'..."
        k3d cluster create "${SENTINEL_CLUSTER_NAME}" \
            --servers "${SENTINEL_SERVER_COUNT}" \
            --agents "${SENTINEL_AGENT_COUNT}" \
            --k3s-arg "--disable=traefik@server:0" \
            --wait
        print_success "Cluster '${SENTINEL_CLUSTER_NAME}' created and ready."
    else
        print_success "Cluster '${SENTINEL_CLUSTER_NAME}' already exists."
    fi

    print_info "Ensuring project namespaces exist..."
    kubectl create namespace "${SENTINEL_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace "${SENTINEL_AGENT_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespaces '${SENTINEL_NAMESPACE}' and '${SENTINEL_AGENT_NAMESPACE}' are ready."
}

destroy_cluster() {
    print_info "Destroying cluster '${SENTINEL_CLUSTER_NAME}'..."
    k3d cluster delete "${SENTINEL_CLUSTER_NAME}"
    print_success "Cluster '${SENTINEL_CLUSTER_NAME}' destroyed."
}

# --- Core Stack Deployment Functions ---
deploy_stack() {
    print_info "Deploying Sentinel stack into namespace '${SENTINEL_NAMESPACE}'..."

    print_info "Adding and updating Helm chart repositories..."
    helm repo add strimzi https://strimzi.io/charts/
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    print_info "Deploying Strimzi Kafka Operator..."
    helm upgrade --install "${HELM_STRIMZI_RELEASE_NAME}" strimzi/strimzi-kafka-operator -n "${SENTINEL_NAMESPACE}" --version 0.41.0 --wait --timeout 15m
    print_info "Deploying Kafka Cluster custom resource..."
    # CORRECTED PATH: Removed the incorrect '../'
    kubectl apply -n "${SENTINEL_NAMESPACE}" -f cluster/strimzi-kafka-crd.yaml

    print_info "Deploying ClickHouse..."
    # CORRECTED PATH: Removed the incorrect '../'
    helm upgrade --install "${HELM_CLICKHOUSE_RELEASE_NAME}" bitnami/clickhouse -n "${SENTINEL_NAMESPACE}" -f cluster/clickhouse-values.yaml --wait --timeout 15m

    print_info "Deploying Kube Prometheus Stack..."
    # CORRECTED PATH: Removed the incorrect '../'
    helm upgrade --install "${HELM_PROMETHEUS_RELEASE_NAME}" prometheus-community/kube-prometheus-stack -n "${SENTINEL_NAMESPACE}" -f cluster/prometheus-grafana-values.yaml --wait --timeout 15m

    print_success "Sentinel stack deployment complete."
    print_info "Run './scripts/infra.sh status' to check pod health."
}

teardown_stack() {
    print_info "Tearing down Sentinel stack in namespace '${SENTINEL_NAMESPACE}'..."
    helm uninstall "${HELM_PROMETHEUS_RELEASE_NAME}" -n "${SENTINEL_NAMESPACE}" --wait || true
    helm uninstall "${HELM_CLICKHOUSE_RELEASE_NAME}" -n "${SENTINEL_NAMESPACE}" --wait || true
    # CORRECTED PATH: Removed the incorrect '../'
    kubectl delete -n "${SENTINEL_NAMESPACE}" -f cluster/strimzi-kafka-crd.yaml || true
    helm uninstall "${HELM_STRIMZI_RELEASE_NAME}" -n "${SENTINEL_NAMESPACE}" --wait || true
    kubectl delete namespace "${SENTINEL_NAMESPACE}" || true
    kubectl delete namespace "${SENTINEL_AGENT_NAMESPACE}" || true
    print_success "Sentinel stack teardown complete."
}

# --- Utility Functions ---
check_status() {
    print_info "Checking status of resources in namespace '${SENTINEL_NAMESPACE}'..."
    kubectl get pods -n "${SENTINEL_NAMESPACE}"
}

expose_grafana() {
    print_info "Forwarding Grafana port to http://localhost:3000 ..."
    print_info "Use username 'admin' and the password from your created secret."
    print_info "Press Ctrl+C to stop."
    kubectl port-forward -n "${SENTINEL_NAMESPACE}" "svc/${HELM_PROMETHEUS_RELEASE_NAME}-grafana" 3000:80
}

# --- Main Entry Point ---
main() {
    if [[ $# -eq 0 ]]; then
        print_error "No command specified."
        echo "Usage: $0 {check|up|down|deploy|full-up|teardown|status|expose-grafana}"
        exit 1
    fi

    case "$1" in
        check) check_dependencies ;;
        up) check_dependencies; create_cluster ;;
        down) check_dependencies; destroy_cluster ;;
        deploy) check_dependencies; deploy_stack ;;
        full-up) check_dependencies; create_cluster; deploy_stack ;;
        teardown) check_dependencies; teardown_stack ;;
        status) check_dependencies; check_status ;;
        expose-grafana) check_dependencies; expose_grafana ;;
        *)
            print_error "Invalid command: $1"
            echo "Usage: $0 {check|up|down|deploy|full-up|teardown|status|expose-grafana}"
            exit 1
            ;;
    esac
}

# Execute main function only if the script is run directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi