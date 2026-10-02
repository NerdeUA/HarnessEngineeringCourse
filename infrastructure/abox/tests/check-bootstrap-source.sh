#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
source_dir="$root/infrastructure/abox"
require() {
  local file=$1 text=$2
  grep -Fq -- "$text" "$root/$file" || { echo "FAIL: $file is missing: $text" >&2; exit 1; }
}

require infrastructure/abox/bootstrap/variables.tf 'default     = "oci://ghcr.io/nerdeua/harnessengineeringcourse/abox"'
require infrastructure/abox/bootstrap/variables.tf 'default = "releases-llmd-embeddings"'
require infrastructure/abox/bootstrap/variables.tf 'default     = "0.1.0"'
require infrastructure/abox/bootstrap/flux.tf 'url: ${var.oci_registry}/${var.releases_artifact}'
require infrastructure/abox/bootstrap/flux.tf 'path: ./crds'
require infrastructure/abox/bootstrap/flux.tf 'dependsOn:'
require infrastructure/abox/bootstrap/flux.tf 'path: ./'
require README.md '# HarnessEngineeringCourse'
require README.md 'Course-owned ABox source'
require docs/lab-7/README.md 'course-owned OCI artifact'
require docs/lab-7/README.md 'rollback'

if grep -REn --exclude='*.lock.hcl' 'gh[pousr]_[A-Za-z0-9]{15,}|github_pat_[A-Za-z0-9_]{20,}' \
  "$source_dir/bootstrap" "$root/.github/workflows/publish-abox-oci.yaml"; then
  echo 'FAIL: a GitHub credential-like value is present in source' >&2
  exit 1
fi

printf 'PASS: course artifact bootstrap is pinned, phased, documented, and credential-free\n'
