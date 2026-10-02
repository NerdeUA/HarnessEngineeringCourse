#!/usr/bin/env bash
set -euo pipefail

manifest_dir="$(cd -- "$(dirname -- "$0")/../manifests" && pwd)"

require_text() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq -- "$expected" "$manifest_dir/$file"; then
    printf 'FAIL: %s must contain %s\n' "$file" "$expected" >&2
    exit 1
  fi
}

for file in namespace.yaml jaeger.yaml mlflow.yaml otel-collector.yaml kagent-tracing-values.yaml kustomization.yaml; do
  if [[ ! -f "$manifest_dir/$file" ]]; then
    printf 'FAIL: missing manifest %s\n' "$file" >&2
    exit 1
  fi
done

require_text namespace.yaml 'name: lab7'
require_text jaeger.yaml 'cr.jaegertracing.io/jaegertracing/jaeger:2.21.0'
require_text jaeger.yaml 'startupProbe:'
require_text jaeger.yaml 'timeoutSeconds: 5'
require_text mlflow.yaml 'ghcr.io/mlflow/mlflow:v3.11.1'
require_text mlflow.yaml 'containerPort: 5000'
require_text mlflow.yaml 'startupProbe:'
require_text mlflow.yaml 'timeoutSeconds: 5'
require_text mlflow.yaml '--workers'
require_text mlflow.yaml "'--allowed-hosts=mlflow.lab7.svc.cluster.local,mlflow.lab7.svc.cluster.local:5000,localhost,localhost:5000,127.0.0.1,127.0.0.1:5000,127.0.0.1:15000'"
require_text otel-collector.yaml 'endpoint: 0.0.0.0:4317'
require_text otel-collector.yaml 'startupProbe:'
require_text otel-collector.yaml 'timeoutSeconds: 5'
require_text otel-collector.yaml 'otlp_grpc/jaeger:'
require_text otel-collector.yaml 'otlp_http/phoenix:'
require_text otel-collector.yaml 'otlp_http/mlflow:'
require_text otel-collector.yaml 'endpoint: jaeger.lab7.svc.cluster.local:4317'
require_text otel-collector.yaml 'traces_endpoint: http://phoenix-svc.phoenix.svc.cluster.local:6006/v1/traces'
require_text otel-collector.yaml 'traces_endpoint: http://mlflow.lab7.svc.cluster.local:5000/v1/traces'
require_text otel-collector.yaml 'x-mlflow-experiment-id: "0"'
require_text otel-collector.yaml 'authorization: Bearer ${env:PHOENIX_API_KEY}'
require_text otel-collector.yaml 'secretKeyRef:'
require_text kagent-tracing-values.yaml 'enabled: true'
require_text kagent-tracing-values.yaml 'captureSensitiveContent: false'
require_text kagent-tracing-values.yaml 'endpoint: http://otel-collector.lab7.svc.cluster.local:4317'

printf 'PASS: pinned backends and the three-destination OTLP fan-out are configured\n'
