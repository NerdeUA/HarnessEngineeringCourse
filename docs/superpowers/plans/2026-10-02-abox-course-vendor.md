# ABox-in-Course Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vendor the deployed ABox Lab 4 source and required Lab 7 observability changes into `HarnessEngineeringCourse`, publish it as a course-owned Flux OCI artifact, and verify durable tracing end to end.

**Architecture:** Assemble `infrastructure/abox/` from the `feat/llmd-embeddings` compatibility baseline, port the `feat/otel-demo` semver comparator, retain the branch-specific artifact stream correction already present from `main`, and put the tested Lab 7 Jaeger/MLflow/Collector resources under Flux management. A course-root GitHub Actions workflow publishes only the vendored release bundle to GHCR on an explicit version tag; OpenTofu and the live Flux ResourceSet then use that immutable course artifact.

**Tech Stack:** Git/GitHub Actions, Flux OCI artifacts, GHCR, Kubernetes, OpenTofu, Kustomize, Helm, Jaeger, Phoenix, MLflow, OTel Collector.

**Spec:** `docs/superpowers/specs/2026-10-02-abox-course-vendor-design.md`

## Global Constraints

- Never stage or commit in the separate `abox` checkout; all commits belong to `HarnessEngineeringCourse`.
- Do not copy `.git`, `.terraform`, `bootstrap/abox-config`, Kubernetes Secret data, API keys, or private SSH keys.
- Do not overwrite the existing nested ABox checkout or existing Lab 4/Lab 7 documents.
- Use `feat/llmd-embeddings` as baseline; port only the `feat/otel-demo` `semver: ">=0.0.0"` comparator; this baseline already has the branch-specific OCI artifact stream correction from `main`; do not overlay whole branches.
- Keep Flux active; retain the upstream artifact until the course artifact is published, readable, and reconciled successfully.
- Pin release tags; do not use a floating OCI artifact tag.
- Set `otel.captureSensitiveContent=false` and do not infer semantic/tool spans without observing them.
- Never put GHCR pull credentials or model/Phoenix keys in Git.
- No release tag/push until source, workflow, and GHCR package access are validated and the user explicitly confirms the release action.

## Review Focus

- Branch-only manifest differences may remove Lab 4 workloads: compare rendered package resources before accepting the vendor tree.
- Repeated CRDs or duplicate Collector/MLflow releases may create conflicts: assert one resource identity per rendered bundle.
- GHCR may require authentication for cluster pulls: verify anonymous read or stop before Flux source switch.
- Flux may revert tracing after a successful live-only edit: verify after a full reconciliation interval.
- A2A client decode errors may mask agent failures: record actual protocol response and accept only a successful benign read-only call.

---

### Task 1: Inventory branch snapshots and define the merge manifest

**Files:**
- Read only: `abox/` checkout and its Git refs; `docs/lab-4/`; `docs/lab-7/`.
- Record: exact path/provenance allowlist in the plan-scoped execution ledger under `.superpowers/sdd/2026-10-02-abox-course-vendor/progress.md`.

**Interfaces:**
- Consumes: local refs `origin/feat/llmd-embeddings`, `origin/feat/otel-demo`, `origin/main`.
- Produces: an explicit allowlist of source paths and per-path source branch, with conflicts resolved for shared manifests.

- [x] **Step 1: Capture read-only status and branch deltas**

Run from the course root:

```bash
git -C abox status --short
git -C abox diff --name-status origin/feat/llmd-embeddings..origin/feat/otel-demo
git -C abox diff --name-status origin/feat/llmd-embeddings..origin/main
```

Expected: the pre-existing dirty ABox paths remain untouched; no copy command targets `.git`, `.terraform`, or `bootstrap/abox-config`.

- [x] **Step 2: Inspect only candidate source files and the Lab 7 working manifests**

For every changed release/bootstrap/workflow path, inspect both versions with `git show <ref>:<path>`. Compare the rendered resource names and versions against current `docs/lab-7/` evidence. Mark each candidate `take`, `merge`, or `exclude` with rationale.

Expected: no whole-branch overlay; `triage`, `xray-memory`, Astronomy Shop, and duplicate backends are excluded absent a demonstrated Lab 7 dependency.

- [x] **Step 3: Verify branch ancestry and locate both Flux corrections**

Run:

```bash
git -C abox log --oneline --decorate --all -- releases/bootstrap
git -C abox log -p origin/feat/llmd-embeddings..origin/main -- '*flux*' '*release*' 'bootstrap/*'
```

Expected: confirm `feat/llmd-embeddings` already contains the branch-aware artifact repository selection from `main`, and locate the minimal `semver: ">=0.0.0"` comparator on `feat/otel-demo`; do not import its branch default or unrelated `main` edits.

- [x] **Step 4: Record the allowlist and conflict decisions**

Write the source-branch mapping and excluded paths into the inventory document or this plan before copying. Include shared paths `releases/kustomization.yaml`, `releases/phoenix.yaml`, `bootstrap/flux.tf`, `bootstrap/variables.tf`, and release workflows. Explicitly include the tested `docs/lab-7/manifests/{namespace,jaeger,mlflow,otel-collector,kustomization}.yaml` as vendor inputs; exclude duplicate `feat/otel-demo` MLflow/Collector resources.

Expected: every copied source file has a known provenance and no unreviewed conflict remains.

### Task 2: Vendor the unified ABox source tree

**Files:**
- Create: `infrastructure/abox/` (selected tracked source from the branch allowlist).
- Preserve: existing `abox/`, `HarnessEngineeringCourse/`, and all current `docs/lab-4/` / `docs/lab-7/` files.

**Interfaces:**
- Consumes: Task 1's reviewed allowlist.
- Produces: a self-contained, non-nested-repository ABox source tree based on deployed Lab 4 release structure.

- [x] **Step 1: Verify destination is absent or empty without deleting anything**

Run:

```bash
test ! -e infrastructure/abox || find infrastructure/abox -maxdepth 2 -type f -print
```

Expected: if non-empty, stop and inspect; do not overwrite user data. If absent, continue.

- [x] **Step 2: Copy only allowlisted tracked files from the feature baseline**

Use `git archive origin/feat/llmd-embeddings <allowlisted paths>` or an equivalent path-scoped export into a temporary directory, then copy the reviewed files into `infrastructure/abox/`. Never copy `.git`, `.terraform`, local config, or untracked files.

Expected: baseline provides Lab 4 retrieval agent, embedding model, Qdrant MCP, and its release/bootstrap source.

- [x] **Step 3: Add the tested Lab 7 backend manifests to the vendor bundle**

Copy `namespace.yaml`, `jaeger.yaml`, `mlflow.yaml`, `otel-collector.yaml`, and `kustomization.yaml` from `docs/lab-7/manifests/` into `infrastructure/abox/releases/lab7/`. Do not copy `feat/otel-demo`'s MLflow or Collector HelmReleases because they duplicate these resources and are configured for different telemetry sources.

Expected: the same already-tested Lab 7 Collector and MLflow definitions are available in the release bundle; no unrelated demo/xray/triage resources are copied.

- [x] **Step 4: Keep release configuration changes test-first**

Do not alter the copied release/bootstrap configuration in this task. Task 3 first adds and runs the failing source contract check, then adds the lab7 parent resource, the `semver: ">=0.0.0"` comparator from `origin/feat/otel-demo`, and the tracing values from `docs/lab-7/manifests/kagent-tracing-values.yaml`.

Expected: the test-first step makes all Lab 4, Lab 7, semver, and tracing requirements independently verifiable.

- [x] **Step 5: Verify the vendor tree's provenance and hygiene**

Run:

```bash
find infrastructure/abox -name .git -o -name .terraform -o -name abox-config
git status --short -- infrastructure/abox
```

Expected: first command prints nothing; only intended new course paths appear in Git status. Compare source path manifest against Task 1 allowlist.

### Task 3: Add reproducible source and configuration checks

**Files:**
- Create: `infrastructure/abox/tests/check-release-source.sh`.
- Modify only if needed: `infrastructure/abox/releases/kustomization.yaml`, `infrastructure/abox/releases/kagent.yaml`.

**Interfaces:**
- Consumes: vendored source tree.
- Produces: a shell check returning nonzero for missing Lab 4 baseline resources or Lab 7 resources, duplicate rendered identities, a branch-mixed release selector, or sensitive capture enabled. The course-owned official Qdrant MCP overlay remains documented under `docs/lab-4/` and is not substituted for the feature branch's baseline MCP.

- [x] **Step 1: Write the failing shell assertions**

The script must assert the retrieval agent, embedding model, feature-branch Qdrant MCP, Jaeger, Phoenix, MLflow, and OTel Collector are declared; exactly one rendered resource identity exists per kind/namespace/name; kagent has the expected `lab7` OTLP endpoint and `otel.captureSensitiveContent=false`; and the release input uses a semver selector in its branch-specific OCI repository.

- [x] **Step 2: Run the check against the source bundle**

Run: `bash infrastructure/abox/tests/check-release-source.sh`

Expected: FAIL first if any acceptance value is absent; fix only the owning manifests.

- [x] **Step 3: Make the minimal manifest changes and rerun**

Add `- lab7` to `releases/kustomization.yaml`, port `semver: ">=0.0.0"` to the branch-specific ResourceSet filter in `bootstrap/flux.tf`, and merge the `otel` mapping from the checked-in kagent tracing values snippet into `releases/kagent.yaml`. Run: `bash infrastructure/abox/tests/check-release-source.sh`.

Expected: PASS with a concise result and no secret values printed; the feature baseline's repository path remains unchanged.

- [x] **Step 4: Render the release bundle and check uniqueness**

Use installed `kustomize build infrastructure/abox/releases` or `kubectl kustomize infrastructure/abox/releases`; parse resource `kind/namespace/name` identities and fail on duplicates. Review the output for unrelated branch workloads.

Expected: render succeeds and every resource identity occurs once.

### Task 4: Add course-owned versioned GHCR publisher

**Files:**
- Create: `.github/workflows/publish-abox-oci.yaml`.
- Modify additively: `infrastructure/abox/README.md` (preserve upstream content, add course source ownership and release operation).
- Create: `infrastructure/abox/tests/check-publisher.sh`.

**Interfaces:**
- Consumes: `infrastructure/abox/releases/` and explicit tags matching `abox-vX.Y.Z`.
- Produces: GHCR artifact `ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings:<version>` (confirm GitHub's canonical package naming before adopting exact path) built from the vendored release directory with `packages: write` permission.

- [x] **Step 1: Write publisher contract assertions**

Assert workflow triggers only on `abox-v*` tags and manual dispatch; checks out the tagged course commit; uses least-privilege `contents: read` and `packages: write`; installs/pins Flux CLI; pushes only `infrastructure/abox/releases/`; derives an immutable version tag; and contains no credentials other than GitHub's scoped token.

- [x] **Step 2: Run the publisher check and confirm expected failure**

Run: `bash infrastructure/abox/tests/check-publisher.sh`

Expected: FAIL because workflow/docs are not yet present.

- [x] **Step 3: Implement workflow, source README, and release tag guard**

Use the existing upstream `flux push artifact` pattern but set repository root, OCI URL, source path, and semantic version explicitly. Prevent malformed or floating tags. Do not push a tag in this step.

- [x] **Step 4: Rerun checks and inspect workflow permissions**

Run: `bash infrastructure/abox/tests/check-publisher.sh` and inspect `git diff -- .github/workflows/publish-abox-oci.yaml`.

Expected: PASS; workflow cannot write repository contents or deploy to Kubernetes.

### Task 5: Retarget bootstrap defaults and document safe migration/rollback

**Files:**
- Modify: `infrastructure/abox/bootstrap/variables.tf`.
- Modify: `infrastructure/abox/bootstrap/flux.tf`.
- Modify: `README.md` without deleting existing content.
- Modify: `docs/lab-7/README.md` without changing prior result/evidence.
- Test: `infrastructure/abox/tests/check-bootstrap-source.sh`.

**Interfaces:**
- Consumes: selected course artifact URL and pinned release version variable.
- Produces: new clusters configure the course OCI artifact and its ResourceSet input provider, with documented rollback to upstream artifact.

- [x] **Step 1: Add failing assertions for bootstrap source ownership and pinning**

Check that Terraform/OpenTofu defaults identify the course artifact, accept an explicit immutable version, optionally attach an existing `flux-system` dockerconfigjson Secret to both the OCIArtifactTag provider and generated OCIRepository, preserve two-phase CRD/application Kustomization dependencies, and do not contain token values. Also assert the existing course README text remains present.

- [x] **Step 2: Run the check before implementation**

Run: `bash infrastructure/abox/tests/check-bootstrap-source.sh`

Expected: FAIL until defaults and docs are updated.

- [x] **Step 3: Update OpenTofu variables and Flux ResourceSet inputs**

Set a course-owned OCI repository default and parameterize its version; add optional `oci_pull_secret_name` (default `null`) and template its `secretRef` into both private-package auth points; retain the existing two-phase structure and dependencies. Do not change the live cluster yet.

- [x] **Step 4: Document release, access, migration gates, and rollback**

Explain GitHub package visibility; anonymous pull verification; if private, requirement for a read-only GHCR secret in `flux-system` with secret value injected out of band; exact tag and publisher flow; Flux readiness checks; and rollback to the recorded upstream artifact/version. Preserve unrelated README content.

- [x] **Step 5: Run bootstrap assertions and OpenTofu validation**

Run: `bash infrastructure/abox/tests/check-bootstrap-source.sh`, then `tofu -chdir=infrastructure/abox/bootstrap fmt -check` and `tofu -chdir=infrastructure/abox/bootstrap validate` when provider/plugin access is available.

Expected: checks pass; validation reports no syntax/module errors. Do not initialize by downloading large providers if disk is constrained; use already available cache or report limitation. Executed `tofu init -backend=false -lockfile=readonly` in the isolated temporary worktree, followed by a passing `tofu validate`.

### Task 6: Validate artifact access and request release authorization

**Files:**
- No source changes expected.
- Evidence update only after successful publication and rollout: `docs/lab-7/evidence/`.

**Interfaces:**
- Consumes: reviewed vendor source, tests, course repository credentials, GHCR metadata.
- Produces: explicit readiness decision to publish/switch or a clear blocker; does not alter ABox repository.

- [x] **Step 1: Check local state, permissions, disk, and current Flux source**

Use read-only commands: `git status --short`, `df -h`, and Flux/cluster reads to record current OCI URL, tag, readiness, and whether current GHCR package allows anonymous pull. Do not print secrets.

Observed baseline: the running OCIRepository is Ready on upstream tag `0.9.5`; `releases-crds` is Ready; the app `releases` Kustomization is not Ready because Phoenix HelmRelease timed out waiting for its Deployment. Phoenix and PostgreSQL pods are currently Running/Ready, but the HelmRelease remains Failed. The new GHCR package is not published yet; unauthenticated direct registry request returns an auth challenge (401), which does not establish its eventual visibility.

- [ ] **Step 2: Verify GitHub Actions and package settings without creating a release**

Confirm course repo Actions are enabled, workflow can receive `packages: write`, and package namespace/visibility policy. If package cannot be public, stop before cluster switch and request provision of a read-only GHCR pull secret (never request its value in chat or Git).

This verification remains pending: `gh` is unavailable in the environment, and the new package does not exist until its first approved publication.

- [ ] **Step 3: Run all static checks and review exact diff**

Run all three check scripts, YAML parse/Kustomize render, OpenTofu validation where available, and `git diff --check`. Review staged paths explicitly; do not stage nested `abox/` or `HarnessEngineeringCourse/` directories.

- [ ] **Step 4: Ask user to approve versioned course release action**

Show the exact proposed tag, package URL, and whether it is public or secret-backed. Make no tag or push until explicit confirmation for this release action.

Expected: no external release operation before approval.

### Task 7: Publish, verify, and switch the Flux source

**Files:**
- Course release tag: `abox-vX.Y.Z` (after explicit user approval).
- Live Flux ResourceSet provider/ResourceSet inputs: only after package pull verification.
- Evidence: `docs/lab-7/evidence/`.

**Interfaces:**
- Consumes: approved course commit and immutable release tag.
- Produces: course OCI artifact readable by cluster and Flux-reconciled source; upstream artifact retained for rollback.

- [ ] **Step 1: Publish the approved course release**

Create/push only the approved tag in `HarnessEngineeringCourse`; observe publisher workflow completion. Never create tags or commits in `abox`.

- [ ] **Step 2: Verify artifact metadata and cluster pull access**

Inspect manifest digest and Flux OCIRepository readiness. If public, verify unauthenticated pull. If private, verify the pre-provisioned secret is referenced without printing or exporting its data.

Expected: exact tag resolves to an OCI digest; cluster can pull it before ResourceSet cutover.

- [ ] **Step 3: Update live Flux provider/ResourceSet inputs to pinned course tag**

Change only the active course migration's source URL/tag fields, preserving provider references, intervals, selectors, and dependency ordering. Do not suspend Flux.

- [ ] **Step 4: Wait through a full reconciliation interval and verify both phases**

Check source, provider, ResourceSet, both generated Kustomizations, HelmReleases, and readiness conditions. Verify `otel.tracing.enabled=true`, `otel.captureSensitiveContent=false`, expected OTLP endpoint, and `OTEL_*` env on controller and retrieval agent after the reconciliation interval.

Expected: all Ready and tracing values remain enabled after reconciliation.

- [ ] **Step 5: Roll back if any readiness gate fails**

Restore only the prior recorded OCI URL/tag in ResourceSet input; reconcile and verify all Flux objects Ready. Do not delete the old artifact or suspend Flux.

### Task 8: Verify successful agent trace and close bilingual lab evidence

**Files:**
- Modify/add bilingual evidence under `docs/lab-7/` only after observed results.
- Modify: `docs/lab-7/README.md` with final migration and validation outcome.

**Interfaces:**
- Consumes: ready course-owned Flux artifact and running Lab 7 backends.
- Produces: evidence of a successful benign read-only A2A request and common trace in Jaeger, Phoenix, and MLflow, or exact documented limitation.

- [ ] **Step 1: Reproduce A2A decode issue with raw response evidence**

Run existing client once and capture only sanitized error shape. Compare against a benign read-only request using a compatible client or direct A2A protocol request. Do not expose auth headers, API keys, prompts with sensitive content, or secret values.

- [ ] **Step 2: Require a successful read-only response before trace acceptance**

Verify agent returned a valid result and record request timestamp plus trace ID. If all clients fail due server/protocol mismatch, stop semantic acceptance and document the blocker; do not claim end-to-end success.

- [ ] **Step 3: Locate the same trace in Jaeger, Phoenix, and MLflow**

Record links/IDs and observed span/attribute coverage separately. State whether the model call and tool spans are visible; do not infer missing attributes.

- [ ] **Step 4: Update Ukrainian and English reports in parallel**

Append actual artifact tag/digest, Flux reconciliation status, successful call type, trace IDs, backend observations, and any remaining limitations to paired bilingual documents. Keep existing evidence intact.

- [ ] **Step 5: Run final repository, cluster, and security checks**

Run all static tests, `git diff --check`, confirm Flux is not suspended and all relevant objects Ready, inspect Git status for secret/cache/nested repo files, and verify `git -C abox status --short` matches the original dirty state.

Expected: all course-owned changes are committed only in `HarnessEngineeringCourse`; no secret, cache, or child-repository commit is present.
