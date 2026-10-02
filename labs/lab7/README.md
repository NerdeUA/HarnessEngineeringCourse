# Laboratory 7 — GenAI observability comparison

## Execution status

This lab is **not yet complete**. The running `abox` cluster is on the
`feat/llmd-embeddings` release (OCI tag `0.9.5`). Switching it to the
`feat/otel-demo` release was not completed. During the lab 4 MCP rollout,
etcd logged a fatal `failed to save Raft hard state and entries: input/output
error` and the Kubernetes API began returning EOF. The cluster has not been
restarted or recreated to protect its existing state.

The current observations below are therefore an evaluation plan, not measured
results. No traces were fabricated.

## Planned procedure

1. After backing up the existing cluster state, reconcile the `feat/otel-demo`
   release and verify the Astronomy Shop demo, OpenTelemetry Collector,
   Phoenix, and MLflow workloads.
2. Invoke Astronomy Shop agent with a fixed prompt and capture its trace ID.
3. Confirm the same run is available in the OTel backend, Phoenix, and MLflow;
   record trace/span coverage, prompt and completion visibility, tool-call
   visibility, latency, token/cost data, filtering, and usability.
4. Record UI screenshots and the exact query/run identifiers. Keep backend
   differences explicit: these systems may receive different spans or
   metadata, so compare only the same run and instrumented fields.

## Comparison rubric (results pending)

| Dimension | OpenTelemetry | Phoenix | MLflow |
|---|---|---|---|
| Distributed traces / spans | Pending live verification | Pending live verification | Pending live verification |
| Prompt, completion, tool-call detail | Pending | Pending | Pending |
| GenAI metadata and evaluations | Pending | Pending | Pending |
| Search, filtering, and run comparison | Pending | Pending | Pending |
| Setup and operational overhead | Pending | Pending | Pending |

## Blockers to resolve

- Repair or safely restore the local KinD etcd I/O failure before further
  cluster operations.
- The public release bundle is accessible, but the `triage-core` and
  `triage-agent` Helm charts are private GHCR packages (anonymous requests
  returned HTTP 401 during preparation). If required by the OTel release,
  configure image/chart credentials locally; never commit credentials.
- Resume with the exact `feat/otel-demo` release/tag and validate health before
  trying to capture traces.
