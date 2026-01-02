#!/usr/bin/env bash
set -euo pipefail

########################################
# GITLAB RUNNER (optional)
########################################
# Installs GitLab Runner Helm chart (Kubernetes executor)
# Only runs if GITLAB_REGISTRATION_TOKEN is set.

GITLAB_URL="${GITLAB_URL:-https://gitlab.com/}"
GITLAB_NAMESPACE="${GITLAB_NAMESPACE:-gitlab-runners}"
GITLAB_RELEASE_NAME="${GITLAB_RELEASE_NAME:-gitlab-runners}"

if [[ -n "${GITLAB_REGISTRATION_TOKEN:-}" ]]; then
  echo "==> Installing GitLab Runner into namespace ${GITLAB_NAMESPACE}..."
  # Add / update repo (ignore if already exists)
  helm repo add gitlab https://charts.gitlab.io >/dev/null 2>&1 || true
  helm repo update gitlab >/dev/null 2>&1 || true

  helm upgrade --install "${GITLAB_RELEASE_NAME}" \
    --namespace "${GITLAB_NAMESPACE}" \
    --create-namespace \
    --set gitlabUrl="${GITLAB_URL}" \
    --set runnerRegistrationToken="${GITLAB_REGISTRATION_TOKEN}" \
    --set rbac.create=true \
    --set concurrent=12 \
    --set runners.tags="{eks,k8s}" \
    gitlab/gitlab-runner

  echo "==> GitLab Runner installed."
  echo "    Use tags: eks,k8s in your .gitlab-ci.yml"
else
  echo "==> Skipping GitLab Runner (GITLAB_REGISTRATION_TOKEN not set)"
fi