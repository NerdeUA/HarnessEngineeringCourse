# Lab 7 report — OpenTelemetry, MLflow, and Phoenix

Date: 2026-10-02. Environment: ABox Kubernetes cluster, kagent 0.x, one OTLP Collector and three trace backends.

## What was done

- Deployed Jaeger 2.21.0, MLflow 3.11.1, and OpenTelemetry Collector contrib 0.161.0 in `lab7`.
- Configured one OTLP/gRPC receiver and three destinations: Jaeger OTLP/gRPC, Phoenix OTLP/HTTP, MLflow OTLP/HTTP.
- Configured Phoenix API-key auth from a Kubernetes Secret and MLflow experiment ID `0`.
- Temporarily enabled kagent OTLP tracing and explicitly disabled sensitive-content capture; Flux later restored tracing to disabled because the source change was intentionally left uncommitted.
- Sent an A2A request to `retrieval-agent` and observed trace ID `644cf78a6f9aa2973256730a078d7832` at each backend.

## Comparison

| Solution | What it showed in this run | Strength for GenAI | Limitation observed |
|---|---|---|---|
| OpenTelemetry + Collector (instrumentation/transport) | A single OTLP ingress and exporter fan-out to all destinations | Open, backend-independent conventions; central routing and processing | OTel is not itself the trace-analysis UI or durable storage backend |
| Jaeger 2 | Trace lookup returned three spans: controller A2A POST, `invoke_agent`, and retrieval-agent POST | Clear end-to-end service trace timeline; useful general distributed tracing baseline | This demo uses in-memory storage; no LLM-specific evaluation workflow, and the trace had no model/tool child span |
| MLflow Tracing | Experiment `0` search returned eight traces in the query window, including the same trace ID; returned records were `OK` | Fits GenAI traces alongside experiments and evaluation workflows | Experiment selection/organization is part of the workflow; this setup is a single-worker SQLite demo |
| Phoenix | Default project query returned the same trace ID with three spans | Purpose-built LLM trace/project interface and GenAI analysis workflow | Requires API-key auth for OTLP ingest; observed spans here were service-level, without LLM semantic detail |

## Findings and limitations

The same trace ID in all three stores confirms that OTel fan-out and backend ingestion worked. Trace consistency is a useful interoperability check, but not by itself a quality evaluation of model answers. The kagent CLI failed while decoding the JSON-RPC response because `error.data` had an object shape where the CLI expected a typed array. Although the controller endpoint returned HTTP 200 and produced spans, this evidence cannot establish a successful agent response. The emitted trace contained only three service/agent spans, not model/tool child spans. Sensitive content was intentionally disabled, so prompts and completions were not exposed in trace data.

Phoenix initially required valid system-key authentication, while MLflow required an explicit host allowlist including host:port variants. After these settings were corrected, Collector and all backends became ready and the trace was visible across the backends. The trace was generated during a live tracing-enabled window. Flux was resumed afterward; its next reconciliation restored `OTEL_TRACING_ENABLED=false` because the source ABox HelmRelease change was intentionally not committed. Thus the backends and evidence are real, but tracing is not currently persistent/enabled from the reconciled ABox source. The course repository contains the values snippet and reproducible instructions; applying the snippet to a GitOps-managed source and publishing that source is required for persistence. No ABox commit was made.

## Conclusion

The three products solve different layers rather than being direct substitutes: OTel standardizes instrumentation and transport, Jaeger gives a general trace timeline, MLflow associates traces with experiments/evaluation, and Phoenix focuses on LLM trace analysis. For this lab, OTel Collector fan-out was a practical way to compare them on identical data. Before using the setup for real evaluation, fix the CLI/A2A response decoding issue, demonstrate successful agent/tool execution, and decide on persistent storage, retention, and data-redaction policy.

See [ADR-L7](ADR-lab-7-en.md), the [Ukrainian report](report-uk.md), and [recorded evidence](evidence/).

## Revalidation — 2026-10-03

Jaeger, MLflow, and the OTel Collector Deployments were still Ready, and the Phoenix and PostgreSQL Pods were Running. Flux's `releases` Kustomization remained unhealthy because the Phoenix HelmRelease was Stalled after its earlier install timeout. A fresh read-only A2A `message/stream` request to `k8s-agent` reached the controller, but the agent returned `401 invalid_api_key` from OpenAI, so no successful agent answer was observed. The ModelConfig references Secret `kagent/kagent-openai`, key `OPENAI_API_KEY`; its value was not read or recorded. The previous shared trace remains valid evidence of backend fan-out, but this revalidation does not establish fresh end-to-end tracing or a successful agent invocation. Remediation requires replacing that Secret out of band, then re-running the benign task and correlating its trace across the three backends. Course artifact publication/source migration and persistent tracing are still pending package-access authorization.
