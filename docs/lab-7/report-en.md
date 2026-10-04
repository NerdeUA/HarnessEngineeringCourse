# Lab 7 report — OpenTelemetry, MLflow, and Phoenix

Date: 2026-10-04. Environment: ABox Kubernetes, kagent `0.10.1`, OpenTelemetry Collector contrib `0.161.0`, Jaeger `2.21.0`, MLflow `3.11.1`, Phoenix `12.0.10`.

## Completed work

- Deployed and configured Jaeger, MLflow, Phoenix, and one OpenTelemetry Collector. The Collector receives OTLP/gRPC and exports to Jaeger (OTLP/gRPC), MLflow (OTLP/HTTP, experiment `0`), and Phoenix (OTLP/HTTP with a Kubernetes-Secret-backed API key).
- Persisted the setup in the course-owned ABox bundle; published private OCI artifact `0.1.3` and reconciled it with Flux (`Ready=True`). No commit was made to the upstream `abox` repository.
- Kept kagent `captureSensitiveContent: false` and added Collector-side removal of model request/response, tool input/output, and generic GenAI prompt/completion payload attributes. Restarted the Collector after its ConfigMap update and verified a successful deployment rollout.
- Issued a read-only A2A request to `k8s-agent`. The agent completed successfully, invoked `k8s_get_resources`, and returned the names and Ready condition of the three Kubernetes nodes.
- Correlated the same trace, `1495d32fea9a55da394f79de961f3878`, in Jaeger, MLflow experiment `0`, and Phoenix project `default`.

## Comparison

| Solution | Evidence from the same run | Strength for GenAI | Limitation observed |
|---|---|---|---|
| OpenTelemetry + Collector | One OTLP ingress; transform/redaction followed by fan-out to all three exporters | Vendor-neutral instrumentation, centralized processing, and independent destinations | OTel is a standard and pipeline, not a trace-analysis UI or durable backend by itself |
| Jaeger 2 | Same trace contains `invoke_agent`, model spans for `gpt-4.1-mini`, and `execute_tool k8s_get_resources`; payload fields are absent | Best of these three for a readable distributed-span timeline and service relationships | Demo storage is in-memory; limited GenAI experiment/evaluation workflow |
| MLflow Tracing | Same trace ID found in experiment `0`, state `OK` | Convenient association of traces with experiments and evaluation workflows | Experiment-centric organization; this cluster uses a single-worker SQLite demo |
| Phoenix | Same trace ID found in project `default` | LLM-focused trace/project interface and GenAI-oriented analysis | OTLP ingestion requires a valid system API key; deployment and retention need operational care |

## Findings and limitations

The same trace ID in all three backends verifies end-to-end export and ingestion for one successful agent run. Semantic model and tool spans make the run more useful than a controller-only trace. This is an observability comparison, not a statistical or human evaluation of answer quality.

An important privacy finding was that `captureSensitiveContent: false` alone did not remove every raw `gcp.vertex.agent.*` request/response/tool payload attribute. The course-owned Collector transform now deletes those attributes and matching generic GenAI payload keys before exporter fan-out. The final trace retained model/operation/token-count/tool-name metadata while containing none of the checked raw-payload keys.

Previously exported pre-redaction traces remain in backend storage and must be treated as sensitive. This work did not purge historical records. Jaeger is in-memory; MLflow uses SQLite and a PVC; Phoenix uses its configured database. Apply each backend's retention/deletion procedure if historical data must be removed. The Collector mounts its configuration through ConfigMap `subPath`, so a future ConfigMap change requires a Collector rollout restart; Flux does not trigger it automatically here.

## Conclusion

Lab 7 is complete: all three observability solutions received the same successful agent trace, and their differences were documented. OTel/Collector is the common transport and policy layer; Jaeger provides general distributed tracing; MLflow supplies experiment-oriented trace organization; Phoenix focuses on LLM traces and project analysis. The evidence and reproducible instructions are in [the Lab 7 README](README.md), [ADR](ADR-lab-7-en.md), and [final verification](evidence/final-verification.md).
