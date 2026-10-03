# ADR-L7 — GenAI observability architecture

- Status: Accepted for the lab; production suitability not implied
- Date: 2026-10-02
- Context: HarnessEngineeringCourse, ABox/kagent lab cluster

## Context

Lab 7 asks us to inspect OpenTelemetry, MLflow, and Phoenix, obtain an agent trace, and compare the three solutions for GenAI observability. We need a shared instrumentation/export path and distinct user-facing backends. The deployment is a constrained educational cluster; credentials must not enter Git, and prompt/response content should not be captured by default.

## Decision

Use OpenTelemetry OTLP as the instrumentation and transport standard. Route kagent traces through one OpenTelemetry Collector and fan them out to:

1. Jaeger 2 as the vendor-neutral trace explorer and baseline backend.
2. MLflow Tracing as the experiment/run-oriented GenAI tracing and evaluation surface.
3. Phoenix as the LLM-observability-focused trace and project analysis surface.

Use OTLP/gRPC from kagent to the Collector. The Collector exports to Jaeger via OTLP/gRPC and to MLflow and Phoenix via OTLP/HTTP. MLflow receives experiment ID `0`; Phoenix receives a Bearer system API key sourced only from a Kubernetes Secret. Keep `captureSensitiveContent: false`. Pin container versions in manifests. The lab Jaeger instance is ephemeral in-memory storage; MLflow uses a small PVC and SQLite and is a single-worker demo, not a high-availability deployment.

## Alternatives considered

- Direct agent-to-each-backend exporters: rejected because it multiplies agent configuration and couples agents to vendor endpoints.
- Jaeger alone: rejected because it does not provide the same GenAI experiment/evaluation workflow as MLflow and Phoenix.
- MLflow or Phoenix alone: rejected because a standard OTel collector plus a general trace backend gives a useful interoperable baseline and makes fan-out explicit.
- Capture prompt/completion content: rejected for the default lab setup due to privacy and secret-leak risk.

## Consequences

- One OTLP endpoint centralizes routing and makes adding/removing an exporter independent of agent configuration.
- Three backends duplicate trace storage and require exporter-specific auth, protocol, and retention configuration.
- Jaeger demonstrates standard distributed-trace exploration; MLflow offers experiment-oriented GenAI traces; Phoenix provides an LLM-focused project view. Their UI and query semantics are not interchangeable.
- With sensitive content capture off, trace metadata is safer but semantic debugging/evaluation context is limited.
- Demo persistence and availability are limited: Jaeger data is lost on restart; MLflow's single replica/PVC is not production-grade.

## Verification and decision record

Trace `644cf78a6f9aa2973256730a078d7832` was observed in Jaeger, MLflow experiment `0`, and the Phoenix default project. Jaeger and Phoenix showed the same three service/agent spans. MLflow returned eight traces in the query window, including the matching trace; the observed MLflow trace records were in OK state. See [the report](report-en.md) and [evidence](evidence/).

The agent CLI surfaced a JSON-RPC response decode error (`error.data` object could not be decoded as the expected typed array). The controller request itself returned HTTP 200 and generated exportable spans, but this run does not establish that the requested task completed successfully or that LLM/tool semantic spans were emitted. This is a known limitation of the evidence, not evidence of a successful answer.

Revalidation on 2026-10-03: a direct read-only A2A stream reached `k8s-agent`, but the model call failed with OpenAI `401 invalid_api_key`. The ModelConfig points to `kagent/kagent-openai` (`OPENAI_API_KEY`); the Secret value was not inspected. Flux's app Kustomization also remains unhealthy because the Phoenix HelmRelease is Stalled. Keep the architecture decision, but treat successful agent execution and durable GitOps tracing as pending until credentials are corrected, a fresh trace is compared in all three backends, and the reviewed course artifact is published and reconciled.

Follow-up on 2026-10-03: a targeted reconcile of the already-running Phoenix HelmRelease succeeded, and the app Kustomization returned Healthy on upstream artifact `0.9.5`. This confirms the earlier Phoenix status was recoverable without changing its spec; it does not resolve the model credential or course artifact gates.

After the user rotated the OpenAI key, a direct A2A read-only node-list task completed and returned the three cluster nodes as Ready. The currently reconciled kagent HelmRelease still lacks the course `otel` values; therefore this proves agent execution, not fresh GenAI trace ingestion. Durable tracing and same-run backend comparison remain gated on course artifact publication and reconciliation.

Final course cutover (2026-10-03): private artifact `oci://ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings:0.1.2` was pulled by Flux with `flux-system/ghcr-pull`; revision `0.1.2@sha256:843f72154cc59d2435ff8a90912a8f36f99bf91fab0e1a7d2e5b64f702cacb2b` is Ready on both `releases-crds` and `releases`. The live `ResourceSetInputProvider` now uses the course OCI URL, numeric semver filter, and the generated `OCIRepository` carries the private pull Secret. The deployed kagent values have OTLP/gRPC tracing enabled and `captureSensitiveContent: false`. Neo4j's previously committed credential was treated as compromised and rotated in the live database; authentication was verified after the final Helm upgrade using `neo4j/neo4j-password`, while `kagent/neo4j-auth` feeds the MCP server. No credential value was read into the report or committed. An intermediate `0.1.1` artifact was superseded because Helm removed its formerly chart-owned `neo4j-auth` Secret; `0.1.2` uses the collision-free name. Git history was not rewritten; the old value is invalidated, and the old GHCR package remains private.

The final benign post-cutover A2A request did not succeed: OpenAI returned `401 invalid_api_key`. A masked error showed `OPENAI_A**_KEY`; this suggests (but does not prove, since the Kubernetes Secret was not read) that the effective credential is still a placeholder. Jaeger recorded the failed GenAI trace `cb7d9f9a5bbd019bb90cbe603ac99481`, with error-status model/agent spans. This verifies post-cutover instrumentation but is not a successful task and was not newly correlated across MLflow and Phoenix. The remaining Lab 7 gate is to correct the OpenAI Secret out of band and correlate a successful post-cutover trace in all three backends.
