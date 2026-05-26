#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/app/scripts/bash/ensure-dev-env.sh"
cd "${REPO_ROOT}"
exec "$@"
