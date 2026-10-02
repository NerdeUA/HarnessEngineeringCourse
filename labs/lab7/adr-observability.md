# ADR: Comparing observability systems for GenAI traces

- Status: Proposed; execution pending
- Date: 2026-10-02

## Context

Laboratory 7 asks for traces from an agent and a comparison of standard
OpenTelemetry, MLflow, and Phoenix for GenAI observability. The comparison must
use the same agent run and should distinguish raw telemetry from the
GenAI-specific span attributes that each backend actually receives.

## Decision

Use the Astronomy Shop agent from the `feat/otel-demo` release as the common
workload. Send one fixed prompt, retain its run/trace ID, and inspect the
corresponding data in all three UIs. Evaluate distributed trace navigation,
prompt/completion and tool-call visibility, GenAI metadata, evaluation support,
filtering, run comparison, and operational overhead. Capture screenshots and
record the exact configuration and build/release versions.

## Consequences

- A single reproducible run makes the comparison interpretable.
- Missing fields must be recorded as missing rather than inferred from another
  backend.
- Results cannot be claimed until all three UIs contain the same run.
- The test is currently blocked by a fatal etcd I/O error in the local cluster
  and unresolved access to private GHCR charts. See `README.md`.

## Result

Pending. Do not score the systems until the planned procedure is completed.
