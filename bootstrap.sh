#!/bin/bash

# ==============================================================================
# Project Sentinel: Master Bootstrap Script (V2.2 - Secret Fix)
#
# Description:
#   This is the main entry point for setting up the entire Sentinel local
#   development environment. V2.2 fixes the Grafana secret creation.
#
# ==============================================================================

# --- Script Setup ---
set -euo pipefail
source "$(dirname "$0")/scripts/env.sh" || exit 1

# --- Helper Functions (self-contained for clarity) ---
print_info() { echo -e "\033[34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }

# --- Main Execution ---

print_info "🚀 Starting Project Sentinel Environment Bootstrap..."

# Step 1: Set up the K8s cluster and namespaces.
print_info "--- Step 1 of 3: Setting up Kubernetes Cluster ---"
./scripts/infra.sh up
print_success "Kubernetes cluster is up and running."

# Step 2: Generate and apply complete, valid secrets.
print_info "--- Step 2 of 3: Generating Secure Secrets ---"
if [ -z "${CLICKHOUSE_PASSWORD:-}" ]; then
    CLICKHOUSE_PASSWORD=$(openssl rand -base64 16)
    print_warning "Generated a random password for ClickHouse."
fi
if [ -z "${GRAFANA_PASSWORD:-}" ]; then
    GRAFANA_PASSWORD=$(openssl rand -base64 16)
    print_warning "Generated a random password for Grafana."
fi

# Create the ClickHouse secret.
kubectl create secret generic clickhouse-sentinel-secret \
  --from-literal=clickhouse-password="${CLICKHOUSE_PASSWORD}" \
  -n "${SENTINEL_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# --- THIS COMMAND IS UPDATED ---
# The Grafana secret now includes the 'admin-user' key, which the chart requires.
kubectl create secret generic grafana-sentinel-secret \
  --from-literal=admin-user='admin' \
  --from-literal=admin-password="${GRAFANA_PASSWORD}" \
  -n "${SENTINEL_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

print_success "Kubernetes secrets for ClickHouse and Grafana created."
echo
print_warning "🔐 PLEASE SAVE THIS GENERATED PASSWORD! 🔐"
echo "Grafana Admin Username: admin"
echo "Grafana Admin Password: ${GRAFANA_PASSWORD}"
echo

# Step 3: Deploy the core data and observability stack.
print_info "--- Step 3 of 3: Deploying Core Infrastructure Stack ---"
./scripts/infra.sh deploy

# --- Final Output ---
echo
print_success "🎉 Project Sentinel bootstrap complete! 🎉"
echo
print_info "The core infrastructure is deployed. To monitor the status, run:"
print_info "  ./scripts/infra.sh status"
echo
print_info "To access the Grafana UI, run the following command and then open http://localhost:3000 in your browser:"
print_info "  ./scripts/infra.sh expose-grafana"