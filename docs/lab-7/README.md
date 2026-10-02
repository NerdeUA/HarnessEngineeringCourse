# Lab 7 — GenAI observability

This lab compares standard OpenTelemetry collection with Jaeger, MLflow Tracing, and Arize Phoenix. The course-owned ABox source is in `infrastructure/abox/`; the nested `abox/` checkout is only an upstream reference. `infrastructure/abox/releases/lab7/` is the Flux-managed copy of the tested Lab 7 backend manifests, while `docs/lab-7/manifests/` remains a standalone lab setup and test fixture.

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

For a GitOps-managed ABox cluster, keep Flux as the source of truth and publish the reviewed course-owned OCI artifact before changing its source. Do not use `kubectl apply` to override resources already managed by Flux. The exact course package is `oci://ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings:<semver>`; the publisher workflow accepts only `abox-vX.Y.Z` tags. The package must be readable from the cluster. Prefer public read access; if GHCR is private, provision a read-only `kubernetes.io/dockerconfigjson` Secret in `flux-system` out of band and pass its name as `oci_pull_secret_name` to OpenTofu. The bootstrap attaches that reference to both the tag provider and generated OCIRepository. Never commit the Secret or its token.

For an isolated/manual lab cluster that is not managed by the ABox Flux release, the checked-in docs manifests can still be applied directly:

```sh
kubectl apply -k docs/lab-7/manifests
kubectl -n lab7 wait --for=condition=Available deployment/jaeger deployment/mlflow deployment/otel-collector --timeout=5m
kubectl -n lab7 get pods
```

The vendored `infrastructure/abox/releases/kagent.yaml` carries the same OTLP/gRPC tracing values and sets `otel.captureSensitiveContent=false`. For GitOps installs, change that source and publish a new course artifact; do not rely on a live-only patch for persistence. Preserve the existing two-phase CRD/application reconciliation when editing the bundle.

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

## Course release migration and rollback

Before switching a running cluster, confirm the course artifact tag exists, its digest is known, and Flux can pull it. The upstream source remains available at `oci://ghcr.io/den-vasyliev/abox/releases-llmd-embeddings`; the current upstream tag recorded during the migration design was `0.9.5`. Record the live input before changing it:

```sh
kubectl -n flux-system get resourcesetinputprovider releases-image -o yaml \
  > /tmp/abox-releases-image-before-course-migration.yaml
```

After the course package is readable, change the `releases-image` provider URL to `oci://ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings` and let its ResourceSet reconcile. For a private package, also set the provider's `secretRef.name` to the existing `flux-system` Secret; the ResourceSet must include the same `secretRef` on its generated OCIRepository. Verify the generated OCIRepository and both Kustomizations are Ready, the CRD Kustomization precedes the app Kustomization, and tracing remains enabled after at least one two-minute reconcile interval.

If readiness fails, restore the captured `releases-image` provider with `kubectl apply -f /tmp/abox-releases-image-before-course-migration.yaml`, then verify the OCIRepository and both Kustomizations return to Ready on the upstream tag. Do not delete the upstream package or leave Flux suspended. The live cluster is not retargeted by this documentation/source change alone.

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
