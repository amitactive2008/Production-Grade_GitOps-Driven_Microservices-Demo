#!/usr/bin/env bash
set -euo pipefail

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Export your GITHUB_TOKEN first: export GITHUB_TOKEN=ghp_..." >&2
  exit 1
fi

command -v docker >/dev/null 2>&1 || { echo "docker not found" >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm not found" >&2; exit 1; }

# GitHub username and image prefix
GH_USER="amitactive2008"
IMAGE_PREFIX="ghcr.io/${GH_USER}/microservices-demo"
CHART_REF="ghcr.io/${GH_USER}/onlineboutique:0.10.4"
TAG="v0.10.4"

services=(adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice)

# optional argument: service name or "all" (default)
target="all"
if [ "$#" -ge 1 ]; then
  target="$1"
fi

echo "Writing Docker config for GHCR auth..."
B64=$(printf "%s" "${GH_USER}:${GITHUB_TOKEN}" | base64 -w0)
mkdir -p "$HOME/.docker"
cat > "$HOME/.docker/config.json" <<JSON
{"auths": {"ghcr.io": {"auth": "${B64}"}}}
JSON
chmod 600 "$HOME/.docker/config.json"

build_and_push() {
  local svc="$1"
  local ctx
  if [ "$svc" = "cartservice" ]; then
    ctx="./src/cartservice/src"
  else
    ctx="./src/${svc}"
  fi
  if [ ! -d "$ctx" ]; then
    echo "Skipping $svc: context $ctx not found" >&2
    return 0
  fi
  local image="${IMAGE_PREFIX}/${svc}:${TAG}"
  echo "Building $svc from $ctx -> $image"
  docker build -t "$image" "$ctx"
  echo "Pushing $image"
  docker push "$image"
}

if [ "$target" = "all" ]; then
  for svc in "${services[@]}"; do
    build_and_push "$svc"
  done
else
  build_and_push "$target"
fi

echo "Saving and pushing Helm chart as ${CHART_REF}"
helm chart save helm-chart "${CHART_REF}"
helm chart push "${CHART_REF}"

echo "Done."
