#!/usr/bin/env bash

# Publish the Online Boutique Helm chart to GitHub Container Registry (GHCR).
# Example:
#   TAG=v0.10.4 GHCR_OWNER=amitactive2008 ./docs/releasing/make-helm-chart-ghcr.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT=$SCRIPT_DIR/../..
CHART_DIR="$REPO_ROOT/helm-chart"
TAG="${TAG:?TAG env variable must be specified}"
GHCR_OWNER="${GHCR_OWNER:-amitactive2008}"

log() { echo "[INFO] $1" >&2; }
error() { echo "[ERROR] $1" >&2; exit 1; }

if ! command -v helm >/dev/null 2>&1; then
  error "helm is required but not installed"
fi

cd "$CHART_DIR"

# Update chart version and appVersion to match TAG
python3 - "$TAG" <<'PY'
import re
import sys
from pathlib import Path
path = Path('Chart.yaml')
text = path.read_text()
tag = sys.argv[1]
app_version = tag
chart_version = tag[1:] if tag.startswith('v') else tag
text = re.sub(r'^appVersion:\s*.*$', f'appVersion: "{app_version}"', text, flags=re.MULTILINE)
text = re.sub(r'^version:\s*.*$', f'version: {chart_version}', text, flags=re.MULTILINE)
path.write_text(text)
PY

CHART_NAME=$(python3 - <<'PY'
import re
from pathlib import Path
text = Path('Chart.yaml').read_text()
m = re.search(r'^name:\s*(\S+)', text, flags=re.MULTILINE)
print(m.group(1) if m else 'onlineboutique')
PY
)
CHART_PACKAGE="${CHART_NAME}-${TAG:1}.tgz"
HELM_REPO="oci://ghcr.io/${GHCR_OWNER}/charts"

log "Packaging Helm chart ${CHART_NAME} with tag ${TAG}"
helm package .

log "Pushing ${CHART_PACKAGE} to ${HELM_REPO}"
helm push "$CHART_PACKAGE" "$HELM_REPO"

rm -f "$CHART_PACKAGE"

log "Success: pushed ${CHART_PACKAGE} to ghcr.io/${GHCR_OWNER}/charts"
