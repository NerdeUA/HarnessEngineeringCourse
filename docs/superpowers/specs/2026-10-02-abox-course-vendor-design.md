# ABox-in-Course GitOps Design

## Goal

Make the Lab 7 tracing configuration durable by maintaining the ABox release source inside `HarnessEngineeringCourse`, publishing its Flux release artifact from that repository, and directing the running Flux release reconciler to the course-owned artifact. Preserve the Lab 4 `feat/llmd-embeddings` functionality and never create a commit in the separate `abox` checkout.

## Current state and evidence

- The parent course repository is `NerdeUA/HarnessEngineeringCourse`; the separate ABox checkout is `den-vasyliev/abox`.
- The running Flux `ResourceSetInputProvider` obtains its release tag from OCI artifact `ghcr.io/den-vasyliev/abox/releases-llmd-embeddings`; the current artifact is `0.9.5`. The ResourceSet creates an `OCIRepository` and two Flux Kustomizations, reconciled every two minutes. Therefore, copying files to the course checkout alone cannot prevent Flux from reverting a live-only HelmRelease change.
- The local ABox checkout is on `main`, but its `origin/feat/llmd-embeddings` snapshot differs substantially (38 paths) and is the branch corresponding to the installed release. Replacing that deployed bundle with local `main` risks removing Lab 4 components.
- The ABox worktree has 29 tracked files on `main`, four tracked local modifications, an untracked `bootstrap/abox-config`, and a 207 MB ignored `.terraform` provider cache. The untracked config is 5.5 KB of long-line ASCII and is not needed for publishing a release; its contents will not be copied or printed.
- Course Lab 4 and Lab 7 documents already exist and must remain unchanged except for links or setup notes needed by this migration.

## Chosen design

1. Vendor the tracked source snapshot matching the deployed Lab 4 branch at `infrastructure/abox/`, without a nested `.git` directory or generated `.terraform` contents. Preserve the original ABox checkout and all of its dirty/untracked state.
2. Add the Lab 7 tracing values to the vendored `infrastructure/abox/releases/kagent.yaml`: OTLP/gRPC to the existing `lab7` Collector, with sensitive-content capture disabled.
3. Preserve ABox's existing Gitless Flux/OCI architecture. Add a course-root GitHub Actions workflow that packages `infrastructure/abox/releases/` to a course-owned GHCR artifact on an explicit `abox-vX.Y.Z` tag. Keep the artifact path separate from any future course artifacts and pin release tags rather than using a floating image tag.
4. Change the course copy's OpenTofu defaults and Flux ResourceSet input so new clusters use the course-owned artifact. Update the running Flux ResourceSet input to the same artifact only after the course artifact has been published and verified. Preserve its two-phase CRD/application reconciliation and dependency ordering.
5. Retain the currently deployed upstream artifact until the course artifact is readable and the new source has reconciled successfully. Verify that HelmRelease values and both controller/retrieval-agent tracing environment report enabled after a complete Flux reconciliation interval, then generate a fresh trace in Jaeger, Phoenix, and MLflow.
6. Diagnose the existing A2A CLI JSON-RPC decoding error independently during validation. Use a successful benign read-only agent operation as the acceptance test; if the CLI decoder is the only failure, test a compatible kagent client or direct A2A protocol request. Do not claim semantic/tool spans unless they are actually observed.

## Files and components

- `infrastructure/abox/`: vendored ABox release branch/source, including the ABox docs, Terraform/OpenTofu bootstrap, release manifests, scripts, and source workflows. No nested repository metadata, cache, credentials, or untracked local config.
- Root `.github/workflows/`: course-owner artifact publication workflow configured for `infrastructure/abox/releases/`.
- `infrastructure/abox/bootstrap/variables.tf` and `flux.tf`: course artifact defaults and ResourceSet provider inputs.
- Root `README.md` and `docs/lab-7/README.md`: explain vendored source ownership, safe release/publish flow, artifact access, and verification/rollback.
- `docs/lab-7/`: keep bilingual ADR/report and current evidence; add fresh evidence after migration succeeds.

## Security and operational constraints

- Never copy `.git`, `.terraform`, `bootstrap/abox-config`, Kubernetes Secret data, model API keys, Phoenix API keys, or the private SSH key.
- Never stage or commit in the `abox` repository. All commits belong only to `HarnessEngineeringCourse`; do not push until the locally reviewed source and package permissions are validated.
- Do not remove or overwrite existing course files, Lab 4/Lab 7 reports, or the user's nested checkout. Use a new `infrastructure/abox/` path and preserve the course README by merging documentation, not replacing it.
- The GitHub Actions publisher requires `packages: write`. Flux must be able to read the resulting package. Prefer a public read-only package if organizational policy allows; otherwise a read-only GHCR pull credential must be created in `flux-system` without putting its value in Git.
- Do not suspend Flux as a final state. Do not report persistent tracing until a fresh reconciliation after a full interval leaves it enabled.

## Acceptance criteria

1. The course repository contains the deployed `feat/llmd-embeddings` source layout and Lab 7 values under `infrastructure/abox/`; the separate ABox worktree remains uncommitted.
2. The release workflow builds an OCI artifact from the vendored release tree and pins an immutable/versioned course artifact.
3. The cluster can pull the course artifact, Flux is Ready and resumed, and both CRD/app Kustomizations reconcile in order.
4. After at least one Flux reconciliation interval, the intended HelmRelease still has `otel.tracing.enabled=true`, `otel.captureSensitiveContent=false`, and the OTLP endpoint set to the Lab 7 Collector; tracing environment is present in the controller and retrieval agent.
5. A benign read-only agent call succeeds through an A2A client; its fresh trace is found in Jaeger, Phoenix, and MLflow with a common trace ID. Any missing model/token attributes or known client limitation is documented rather than inferred.
6. Configuration tests, YAML/Kubernetes dry-run, and repository diff checks pass. The cluster's Flux sources are not left suspended.

## Risks and decision gates

- GHCR package visibility or organization policy may prevent anonymous cluster pulls. Check permissions before switching Flux; if public publication is disallowed, obtain a dedicated read-only package credential through the user and store it only as a Kubernetes Secret.
- Publishing the artifact requires pushing a course-repository tag so GitHub Actions can run. No tag/push is made until the user reviews the written implementation plan and explicitly confirms the release action.
- The A2A decode error may be a client/server compatibility defect unrelated to tracing. The migration must not disguise this as successful agent execution.
- Local `main` contains other dirty script/Makefile changes that diverge from the deployed feature branch. The course vendoring base is the deployed feature branch; preserve those edits in the original checkout and do not silently overlay them onto the release branch.
