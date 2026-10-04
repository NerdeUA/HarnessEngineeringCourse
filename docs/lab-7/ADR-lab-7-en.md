# ADR-L7 — GenAI observability architecture

- Status: Accepted for the lab; production suitability is not implied
- Date: 2026-10-04
- Context: HarnessEngineeringCourse ABox/kagent Kubernetes cluster

## Context

Lab 7 requires inspecting OpenTelemetry (OTel), MLflow, and Phoenix, obtaining an agent trace, and comparing their value for GenAI observability. The cluster is an educational environment. Credentials must remain outside Git, and prompt, completion, and tool payloads must not be exported by default.

## Decision

Instrument kagent with OTLP/gRPC to one OpenTelemetry Collector and fan out to three backends: Jaeger 2 over OTLP/gRPC, MLflow Tracing over OTLP/HTTP (experiment `0`), and Phoenix over OTLP/HTTP with a Bearer system key sourced from a Kubernetes Secret. Keep `otel.captureSensitiveContent: false` and apply a Collector transform that removes known `gcp.vertex.agent` request/response/tool payload attributes and generic GenAI prompt/completion/message/tool-argument fields before any exporter sees them. This second control is required: live traces showed that the kagent flag alone did not remove all raw payload attributes.

The course-owned ABox source is published as the private GHCR artifact `ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings:0.1.3`. Flux pulls it using a read-only registry Secret. The upstream `abox` Git repository was not committed to or modified by this course release workflow. Collector, Jaeger, and MLflow versions are pinned in the manifests. Jaeger uses ephemeral in-memory storage; MLflow is a single-worker SQLite demo backed by a small PVC.

## Alternatives considered

- Direct agent exporters to each backend: rejected because it duplicates agent configuration and couples agents to backend-specific endpoints.
- Jaeger alone: rejected because it lacks MLflow's experiment/evaluation workflow and Phoenix's LLM-oriented project analysis.
- MLflow or Phoenix alone: rejected because a standard OTel pipeline and general-purpose trace backend provide an interoperable baseline.
- Capturing prompt/completion or tool payloads for the lab: rejected because it creates unnecessary privacy and secret-leak risk.

## Consequences

- One OTLP endpoint centralizes routing, transformation, and exporter configuration.
- Three destinations duplicate telemetry and have distinct authentication, query, retention, and operational requirements.
- OTel provides instrumentation/transport and Collector processing; Jaeger provides distributed trace exploration; MLflow associates traces with experiments and evaluations; Phoenix provides an LLM-focused trace/project UI. They complement rather than replace one another.
- Payload redaction protects newly exported traces while retaining useful metadata such as model, operation, token counts, tool name, and span relationships. It limits prompt-level debugging by design.
- This is a lab topology, not a production recommendation: Jaeger data is lost on restart, and the MLflow single replica/SQLite deployment is not highly available.

## Verification

On 2026-10-04, Flux reported `Ready=True` for course artifact `0.1.3` at digest `sha256:4beb600712399aa47700a75d25e9cc65185d027451d7b7fa8092be1e825cdd8f`. A read-only A2A request completed successfully through `k8s-agent` and invoked `k8s_get_resources`. Trace `1495d32fea9a55da394f79de961f3878` was found in Jaeger, MLflow experiment `0` (`OK`), and Phoenix project `default`. Jaeger showed agent, model (`gpt-4.1-mini`), and tool spans. Inspection of span attribute keys found no `gcp.vertex.agent.llm_request`, `gcp.vertex.agent.llm_response`, `gcp.vertex.agent.tool_call_args`, `gcp.vertex.agent.tool_response`, nor matching generic GenAI prompt/completion/message/tool-payload keys. See the [report](report-en.md) and [final verification evidence](evidence/final-verification.md).

## Historical data and follow-up

Before this release, traces exported while only `captureSensitiveContent: false` was configured contained raw model/tool payload attributes. The new Collector transform prevents those fields from being exported going forward, but does not retroactively erase already stored traces. Existing pre-redaction records in Jaeger, MLflow, or Phoenix must be treated as sensitive and removed under the operators' retention procedures if deletion is required; no backend-wide purge was performed as part of this lab.

The Collector configuration is mounted through a ConfigMap `subPath`, which does not trigger an automatic pod restart when the ConfigMap changes. After a future config update, restart the Collector and verify the rollout before relying on the new processor. Do not bypass Flux for durable changes.
