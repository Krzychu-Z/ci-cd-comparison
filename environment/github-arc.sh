#!/usr/bin/env bash
set -euo pipefail

### --- USER CONFIGURABLE VARIABLES ---

# EKS
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-masters-thesis-cluster}"

# ARC controller namespace
ARC_SYSTEM_NS="${ARC_SYSTEM_NS:-masters-thesis-arc-system}"

# ARC runner scale set
ARC_RUNNERS_NS="${ARC_RUNNERS_NS:-masters-thesis-arc-runners}"
INSTALLATION_NAME="${INSTALLATION_NAME:-masters-thesis-arc-runner-set}"

# Where runners will register (repo/org/enterprise)
# e.g. "https://github.com/my-org/my-repo" or "https://github.com/my-org"
GITHUB_CONFIG_URL="${GITHUB_CONFIG_URL:-https://github.com/masters-thesis-org}"

### --- VALIDATION ---

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: aws CLI not found in PATH" >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "ERROR: kubectl not found in PATH" >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "ERROR: helm not found in PATH" >&2
  exit 1
fi

if [[ -z "${GITHUB_PAT:-}" ]]; then
  echo "ERROR: GITHUB_PAT environment variable is not set."
  echo "Create a PAT with appropriate scopes and export it, e.g.:"
  echo "  export GITHUB_PAT='ghp_xxx...'"
  exit 1
fi

echo "==> Using AWS region:      ${AWS_REGION}"
echo "==> Using EKS cluster:     ${CLUSTER_NAME}"
echo "==> ARC system namespace:  ${ARC_SYSTEM_NS}"
echo "==> ARC runners namespace: ${ARC_RUNNERS_NS}"
echo "==> Runner config URL:     ${GITHUB_CONFIG_URL}"
echo "==> Installation name:     ${INSTALLATION_NAME}"
echo

### --- CONFIGURE KUBECTL FOR EKS ---

echo "==> Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig \
  --region "${AWS_REGION}" \
  --name "${CLUSTER_NAME}"

echo "==> Verifying cluster connectivity..."
kubectl get nodes -o wide

### --- INSTALL ARC CONTROLLER (scale-set mode) ---

echo "==> Installing Actions Runner Controller (scale-set controller) with Helm..."

# Controller (gha-runner-scale-set-controller)
helm install arc \
  --namespace "${ARC_SYSTEM_NS}" \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

echo "==> Waiting for ARC controller pods to be Ready..."
kubectl wait --for=condition=Ready pods \
  -n "${ARC_SYSTEM_NS}" \
  -l app.kubernetes.io/name=gha-runner-scale-set-controller \
  --timeout=300s || true

kubectl get pods -n "${ARC_SYSTEM_NS}"

### --- INSTALL RUNNER SCALE SET ---

echo "==> Installing runner scale set..."

# NOTE: For production, prefer a Kubernetes Secret instead of passing the PAT inline.
helm install "${INSTALLATION_NAME}" \
  --namespace "${ARC_RUNNERS_NS}" \
  --create-namespace \
  --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
  --set githubConfigSecret.github_token="${GITHUB_PAT}" \
  --set runnerGroup="masters-thesis-arc-group" \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set

echo "==> Checking Helm releases..."
helm list -A

echo "==> Checking controller pods..."
kubectl get pods -n "${ARC_SYSTEM_NS}"

echo "==> Checking runner pods (will spin up when workflows run)..."
kubectl get pods -n "${ARC_RUNNERS_NS}" || true

cat <<EOF

Done.

Next steps:
  1) In your GitHub repo/org, create a workflow with:
       runs-on: ${INSTALLATION_NAME}
  2) Trigger the workflow and watch pods in:
       kubectl get pods -n ${ARC_RUNNERS_NS} -w

For better security, consider:
  - Using a GitHub App instead of a PAT, and
  - Creating a Kubernetes Secret for auth (see ARC docs).
EOF