#!/usr/bin/env bash
set -euo pipefail

########################################
# BITBUCKET RUNNER AUTOSCALER (optional)
########################################
# Deploys Bitbucket Pipelines Runner autoscaler on Kubernetes.
# Only runs if BITBUCKET_WORKSPACE, BITBUCKET_OAUTH_CLIENT_ID and
# BITBUCKET_OAUTH_CLIENT_SECRET are set.

BITBUCKET_NAMESPACE="${BITBUCKET_NAMESPACE:-bitbucket-runners}"
BITBUCKET_AUTOSCALER_DIR="${BITBUCKET_AUTOSCALER_DIR:-./runners-autoscaler}"
BITBUCKET_AUTOSCALER_VERSION="${BITBUCKET_AUTOSCALER_VERSION:-3.9.0}"
BITBUCKET_RUNNER_GROUP_NAME="${BITBUCKET_RUNNER_GROUP_NAME:-masters-thesis-runners}"

install_bitbucket_autoscaler() {
  if [[ -z "${BITBUCKET_WORKSPACE:-}" || -z "${BB_CLIENT_ID:-}" || -z "${BB_CLIENT_SECRET:-}" ]]; then
    echo "==> Skipping Bitbucket autoscaler (BITBUCKET_WORKSPACE / OAUTH vars not set)"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "==> Skipping Bitbucket autoscaler (git not installed)"
    return 0
  fi

  echo "==> Installing Bitbucket Runner autoscaler into namespace ${BITBUCKET_NAMESPACE}..."

  # Clone repo fresh if needed
  if [[ ! -d "${BITBUCKET_AUTOSCALER_DIR}" ]]; then
    git clone https://bitbucket.org/bitbucketpipelines/runners-autoscaler.git "${BITBUCKET_AUTOSCALER_DIR}"
  fi

  pushd "${BITBUCKET_AUTOSCALER_DIR}/kustomize" >/dev/null

  git fetch --all || true
  git reset --hard
  git clean -fd
  git checkout "${BITBUCKET_AUTOSCALER_VERSION}" || echo "   (could not checkout ${BITBUCKET_AUTOSCALER_VERSION}, using current branch)"

  # Base64-encode OAuth creds for the Secret patch (as docs require)
  local bb_client_b64 bb_secret_b64
  bb_client_b64="$(printf '%s' "${BB_CLIENT_ID}" | base64 | tr -d '\n')"
  bb_secret_b64="$(printf '%s' "${BB_CLIENT_SECRET}" | base64 | tr -d '\n')"

  mkdir -p values

  cat > values/runners_config.yaml <<EOF
constants:
  default_sleep_time_runner_setup: 10
  default_sleep_time_runner_delete: 5
  runner_api_polling_interval: 600
  runner_cool_down_period: 300

groups:
  - name: "${BITBUCKET_RUNNER_GROUP_NAME}"
    workspace: "${BITBUCKET_WORKSPACE}"
    labels:
      - "self.hosted"
      - "linux"
      - "runner.docker"
    namespace: "${BITBUCKET_NAMESPACE}"
    strategy: "percentageRunnersIdle"

    parameters:
      min: 1
      max: 3
      scale_up_threshold: 0.5
      scale_down_threshold: 0.2
      scale_up_multiplier: 1.5
      scale_down_multiplier: 0.5
EOF

  cat > values/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../base

configMapGenerator:
  - name: runners-autoscaler-config
    files:
      - runners_config.yaml
    options:
      disableNameSuffixHash: true

namespace: ${BITBUCKET_NAMESPACE}

commonLabels:
  app.kubernetes.io/part-of: runners-autoscaler

images:
  - name: bitbucketpipelines/runners-autoscaler
    newTag: ${BITBUCKET_AUTOSCALER_VERSION}

patches:
  - target:
      version: v1
      kind: Secret
      name: runner-bitbucket-credentials
    patch: |-
      - op: add
        path: /data/bitbucketOauthClientId
        value: "${bb_client_b64}"
      - op: add
        path: /data/bitbucketOauthClientSecret
        value: "${bb_secret_b64}"
  - target:
      version: v1
      kind: Deployment
      labelSelector: "inject=runners-autoscaler-envs"
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/env
        value:
          - name: BITBUCKET_OAUTH_CLIENT_ID
            valueFrom:
              secretKeyRef:
                key: bitbucketOauthClientId
                name: runner-bitbucket-credentials
          - name: BITBUCKET_OAUTH_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                key: bitbucketOauthClientSecret
                name: runner-bitbucket-credentials
EOF

  echo "-> Applying Bitbucket autoscaler manifests..."
  # Namespace will be created by kustomize (from resources) but we can ensure it exists
  kubectl create namespace "${BITBUCKET_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

  kubectl apply -k values

  popd >/dev/null

  echo "==> Bitbucket autoscaler deployed in namespace '${BITBUCKET_NAMESPACE}'."
  echo "    Use labels: self.hosted, linux, runner.docker in bitbucket-pipelines.yml"
}

install_bitbucket_autoscaler