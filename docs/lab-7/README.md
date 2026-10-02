# Lab 7 — GenAI observability

This lab compares standard OpenTelemetry collection with Jaeger, MLflow Tracing, and Arize Phoenix. The checked-in manifests are a reproducible lab setup; all ABox changes remain uncommitted in the nested `abox/` repository.

## Prerequisites

- A working Kubernetes cluster with `kubectl`, the `kagent` namespace, and a `kagent-controller` deployment.
- Phoenix reachable in namespace `phoenix`, with authentication enabled and a Phoenix system API key created.
- The key stored in namespace `lab7` as `phoenix-otel-exporter`, key `api-key`. Do not put the key in Git or terminal recordings. For a fresh cluster, create the namespace and secret interactively:

  ```sh
  kubectl create namespace lab7
  kubectl -n lab7 create secret generic phoenix-otel-exporter --from-literal=api-key='<PHOENIX_SYSTEM_API_KEY>'
  ```

  Replace the placeholder locally; do not save the command with the real value in shell history. On a cluster with external secret management, use that instead.

## Deploy the three backends and collector

```sh
kubectl apply -k docs/lab-7/manifests
kubectl -n lab7 wait --for=condition=Available deployment/jaeger deployment/mlflow deployment/otel-collector --timeout=5m
kubectl -n lab7 get pods
```

Merge `manifests/kagent-tracing-values.yaml` under `spec.values` of the ABox `releases/kagent.yaml` Flux HelmRelease, then reconcile through the normal GitOps source. It enables OTLP/gRPC tracing to the collector and explicitly keeps sensitive content capture disabled. Do not rely on a live-only patch for a persistent installation. In this session, the ABox source edit was deliberately left uncommitted; Flux reconciliation was resumed after the live validation.

The Collector receives OTLP/gRPC on 4317 and fans traces out to Jaeger (OTLP/gRPC), Phoenix (OTLP/HTTP with its system key), and MLflow (OTLP/HTTP with experiment ID `0`). Keep the Phoenix key in a Kubernetes Secret. MLflow is configured as a single-worker demo service backed by a 1 GiB PVC; Jaeger is an all-in-one, in-memory demo backend.

## Open the UIs

Run each port-forward in a separate terminal:

```sh
kubectl -n lab7 port-forward svc/jaeger 16686:16686
kubectl -n lab7 port-forward svc/mlflow 5000:5000
kubectl -n phoenix port-forward svc/phoenix-svc 6006:6006
```

Then open Jaeger at `http://localhost:16686`, MLflow at `http://localhost:5000`, and Phoenix at `http://localhost:6006`.

## Generate and verify a trace

Invoke an agent through the installed kagent CLI (the following read-only task is illustrative):

```sh
kagent invoke --kagent-url http://localhost:18083 --agent k8s-agent --namespace kagent \
  --task 'Use read-only Kubernetes tools to list cluster nodes and report their names and Ready condition only.' --timeout 90s
```

Query Jaeger v2's trace API (not the removed legacy `/api/traces` endpoint):

```sh
curl -fsS http://localhost:16686/api/v3/traces/<TRACE_ID> | \
  jq '[.result.resourceSpans[].scopeSpans[].spans[] | {name, traceId}]'
```

For MLflow, select experiment `Default` (ID `0`) and open Traces. For Phoenix, open the default project and its Traces view. The same trace ID should appear in all three backends when all exporters accept it.

The evidence in `evidence/` records the run. In this run, the controller returned HTTP 200 and all three backends ingested the same trace, but the CLI could not decode the JSON-RPC error payload (`error.data` had an unexpected object shape). Therefore the report does not claim a successful agent answer or semantic LLM/tool spans.

## Configuration validation

```sh
bash docs/lab-7/tests/check-observability-config.sh
kubectl apply --dry-run=client -k docs/lab-7/manifests
```

## References

- [OpenTelemetry OTLP exporter configuration](https://opentelemetry.io/docs/languages/sdk-configuration/otlp-exporter/)
- [kagent tracing](https://kagent.dev/docs/kagent/0.x/observability/tracing/)
- [Jaeger APIs (v2.21)](https://www.jaegertracing.io/docs/2.21/architecture/apis/)
- [MLflow OpenTelemetry trace ingestion](https://mlflow.org/docs/latest/genai/tracing/opentelemetry/ingest/)
- [Phoenix authentication](https://arize.com/docs/phoenix/deployment/authentication)
