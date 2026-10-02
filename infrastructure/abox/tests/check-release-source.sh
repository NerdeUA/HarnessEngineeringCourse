#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
course_root="$(cd "$root/../.." && pwd)"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
require_file() { [[ -f "$1" ]] || fail "missing file: ${1#"$root"/}"; }
require_text() {
  local file=$1 text=$2
  grep -Fq -- "$text" "$root/$file" || fail "$file is missing: $text"
}

for file in \
  releases/kustomization.yaml \
  releases/agent-retrieval.yaml \
  releases/kagent.yaml \
  releases/llama-cpp-embeddings.yaml \
  releases/mcp-servers.yaml \
  releases/qdrant.yaml \
  releases/phoenix.yaml \
  releases/lab7/kustomization.yaml \
  releases/lab7/jaeger.yaml \
  releases/lab7/mlflow.yaml \
  releases/lab7/otel-collector.yaml \
  bootstrap/flux.tf \
  bootstrap/variables.tf; do
  require_file "$root/$file"
done

for resource in agent-retrieval.yaml kagent.yaml llama-cpp-embeddings.yaml mcp-servers.yaml qdrant.yaml phoenix.yaml lab7; do
  require_text releases/kustomization.yaml "- $resource"
done
require_text releases/mcp-servers.yaml 'name: qdrant-mcp'
require_text releases/agent-retrieval.yaml 'name: qdrant-mcp'

# The Lab 7 tested manifests are the single Flux-managed deployment bundle.
require_text releases/lab7/kustomization.yaml '  - mlflow.yaml'
require_text releases/lab7/kustomization.yaml '  - otel-collector.yaml'
require_text releases/lab7/otel-collector.yaml 'endpoint: jaeger.lab7.svc.cluster.local:4317'
require_text releases/lab7/otel-collector.yaml 'traces_endpoint: http://phoenix-svc.phoenix.svc.cluster.local:6006/v1/traces'
require_text releases/lab7/otel-collector.yaml 'traces_endpoint: http://mlflow.lab7.svc.cluster.local:5000/v1/traces'
for file in namespace.yaml jaeger.yaml mlflow.yaml otel-collector.yaml kustomization.yaml; do
  cmp -s "$course_root/docs/lab-7/manifests/$file" "$root/releases/lab7/$file" || \
    fail "vendored Lab 7 manifest differs from docs/lab-7/manifests/$file"
done

# Keep semver ordering within this branch-specific release stream.
require_text bootstrap/flux.tf 'includeTag: "^\\d+\\.\\d+\\.\\d+$"'
require_text bootstrap/flux.tf 'semver: ">=0.0.0"'
require_text bootstrap/variables.tf 'default = "releases-llmd-embeddings"'
require_text bootstrap/variables.tf 'default     = "0.1.0"'

# Trace transport must be enabled without capturing prompt/response content.
require_text releases/kagent.yaml 'captureSensitiveContent: false'
require_text releases/kagent.yaml 'enabled: true'
require_text releases/kagent.yaml 'endpoint: http://otel-collector.lab7.svc.cluster.local:4317'
require_text releases/kagent.yaml 'protocol: grpc'

command -v kubectl >/dev/null || fail 'kubectl is required to render releases'
command -v ruby >/dev/null || fail 'ruby is required to check rendered identity uniqueness'
rendered=$(mktemp)
trap 'rm -f "$rendered"' EXIT
kubectl kustomize "$root/releases" >"$rendered" || fail 'Kustomize release render failed'
ruby - "$rendered" <<'RUBY' || fail 'rendered release bundle contains duplicate resource identities'
require 'yaml'
documents = YAML.load_stream(File.read(ARGV.fetch(0))).compact
counts = Hash.new(0)
documents.each do |document|
  metadata = document.fetch('metadata', {})
  identity = [document['apiVersion'], document['kind'], metadata['namespace'] || 'default', metadata['name']]
  counts[identity] += 1
end
duplicates = counts.select { |_, count| count > 1 }
abort("duplicate identities: #{duplicates.keys.inspect}") unless duplicates.empty?
RUBY

printf 'PASS: Lab 4 resources, Lab 7 backends, pinned branch stream, and safe OTLP tracing are configured\n'
