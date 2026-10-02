#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
workflow="$root/.github/workflows/publish-abox-oci.yaml"
[[ -f "$workflow" ]] || { echo 'FAIL: publisher workflow is missing' >&2; exit 1; }
require() {
  grep -Fq -- "$1" "$workflow" || { echo "FAIL: publisher workflow missing: $1" >&2; exit 1; }
}

require "packages: write"
require "contents: read"
require "abox-v*"
require "workflow_dispatch:"
require "fluxcd/flux2/action@v2.9.6"
require "version: '2.9.6'"
require "./infrastructure/abox/releases"
require "ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings"
require "^abox-v(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"
require "flux pull artifact"
require "flux push artifact"
require "GITHUB_TOKEN"

if grep -Eq -- '--tag[ =]+latest|:[[:space:]]*latest|permissions:[[:space:]]*write-all' "$workflow"; then
  echo 'FAIL: publisher uses a floating tag or broad permissions' >&2
  exit 1
fi

printf 'PASS: course publisher is versioned, path-scoped, and least-privilege\n'
