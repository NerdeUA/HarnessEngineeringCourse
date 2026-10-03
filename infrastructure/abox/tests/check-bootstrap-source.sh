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
require infrastructure/abox/bootstrap/variables.tf 'variable "oci_pull_secret_name"'
require infrastructure/abox/bootstrap/variables.tf 'default     = null'
require infrastructure/abox/bootstrap/flux.tf 'url: ${var.oci_registry}/${var.releases_artifact}'
require infrastructure/abox/bootstrap/flux.tf 'var.oci_pull_secret_name != null'
require infrastructure/abox/bootstrap/flux.tf 'secretRef:'
require infrastructure/abox/bootstrap/flux.tf 'name: ${var.oci_pull_secret_name}'
secret_refs=$(grep -Fc -- 'name: ${var.oci_pull_secret_name}' "$source_dir/bootstrap/flux.tf")
[[ "$secret_refs" == 2 ]] || { echo "FAIL: expected secretRef on both RSIP and OCIRepository, found $secret_refs" >&2; exit 1; }
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
