#!/bin/bash

# ==============================================================================
# Project Sentinel: Environment Configuration
#
# Description:
#   This file centralizes all key environment variables for the project.
#   It uses default values to ensure robustness and allows for overrides
#   for different environments (e.g., local development vs. CI).
#
# Usage:
#   This file is not meant to be executed directly. It is sourced by other
#   scripts like `infra.sh` and `bootstrap.sh`.
# ==============================================================================

# --- Core Project Namespace ---
# A single namespace for all project-related components simplifies management.
export SENTINEL_NAMESPACE="${SENTINEL_NAMESPACE:-sentinel}"


# --- Kubernetes Cluster Configuration ---
# The name of the k3d cluster used for local development.
export SENTINEL_CLUSTER_NAME="${SENTINEL_CLUSTER_NAME:-sentinel-dev}"

# The total number of nodes in the cluster (1 server + N agents).
# A 3-node cluster is recommended to simulate a distributed environment.
export SENTINEL_SERVER_COUNT="${SENTINEL_SERVER_COUNT:-1}"
export SENTINEL_AGENT_COUNT="${SENTINEL_AGENT_COUNT:-2}"


# --- Helm Release Names ---
# Centralizes the names for our Helm deployments.
export HELM_STRIMZI_RELEASE_NAME="${HELM_STRIMZI_RELEASE_NAME:-strimzi-operator}"
export HELM_CLICKHOUSE_RELEASE_NAME="${HELM_CLICKHOUSE_RELEASE_NAME:-clickhouse}"
export HELM_PROMETHEUS_RELEASE_NAME="${HELM_PROMETHEUS_RELEASE_NAME:-prometheus-stack}"


# --- Application Configuration ---
# The namespace where the Sentinel agent itself will be deployed.
export SENTINEL_AGENT_NAMESPACE="${SENTINEL_AGENT_NAMESPACE:-sentinel-agent}"