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
