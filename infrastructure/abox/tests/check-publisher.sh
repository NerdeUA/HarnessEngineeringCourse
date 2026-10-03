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
require "persist-credentials: false"
require "fluxcd/flux2/action@v2.9.6"
require "version: '2.9.6'"
require "ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings"
require "^abox-v(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"
require "flux pull artifact"
require "flux push artifact"
require "GITHUB_TOKEN"
require 'release_dir="${RUNNER_TEMP}/abox-release"'
require 'cp -a infrastructure/abox/releases/. "$release_dir/"'
require 'cp infrastructure/abox/LICENSE "$release_dir/LICENSE"'
require '--path="${RUNNER_TEMP}/abox-release"'
grep -Fq -- 'Apache License' "$root/infrastructure/abox/LICENSE" || {
  echo 'FAIL: vendored ABox license is missing Apache-2.0 text' >&2
  exit 1
}
if grep -Eq '^make push([[:space:]]|$)' "$root/infrastructure/abox/README.md"; then
  echo 'FAIL: vendored ABox README must not execute the upstream ABox release target' >&2
  exit 1
fi
grep -Fq -- 'git tag abox-v0.1.0' "$root/infrastructure/abox/README.md" || {
  echo 'FAIL: vendored ABox README is missing the course-only release example' >&2
  exit 1
}

if grep -Eq -- '--tag[ =]+latest|:[[:space:]]*latest|permissions:[[:space:]]*write-all' "$workflow"; then
  echo 'FAIL: publisher uses a floating tag or broad permissions' >&2
  exit 1
fi

printf 'PASS: course publisher is versioned, path-scoped, and least-privilege\n'
