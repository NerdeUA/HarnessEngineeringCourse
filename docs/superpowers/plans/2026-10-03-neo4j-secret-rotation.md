# Neo4j credential rotation and private course OCI cutover

## Goal

Remove the committed Neo4j password from the course-owned ABox bundle, rotate the live Neo4j credential without losing its PVC data, and move Flux from the upstream ABox artifact to a tested immutable course artifact.

## Steps

1. Change the vendored Neo4j HelmRelease to consume `neo4j-auth` via `neo4j.passwordFromSecret`; change Neo4j MCP to consume the same key through `secretKeyRef`; document out-of-band provisioning, rotation, and rollback in English and Ukrainian.
2. Extend release checks to reject literal Neo4j credentials and require both Secret references. Render and run course validation scripts.
3. Preserve the current auth Secret in-cluster temporarily, create a strong replacement Secret in `neo4j` and `kagent`, rotate the live database password using a short-lived in-cluster Job, and verify the MCP reconnection.
4. Commit and push only to `HarnessEngineeringCourse`; publish a new immutable OCI version `0.1.1` from a course release tag.
5. Verify private registry access with the existing Flux read-only pull Secret; then update both the live tag provider source and generated OCIRepository auth reference. Verify Flux and Lab 7 resources remain Ready.
6. If the cutover is unhealthy, restore the backed-up source configuration. Keep the upstream artifact intact.

## Safety constraints

- Never print, commit, or include the current or replacement password in a command output, workflow log, Git file, or release artifact.
- Never commit to the upstream `abox` repository.
- Do not change the Flux source until the new course artifact can be pulled and verified.
- Preserve the Neo4j PVC and take no action that deletes it.

## Verification

- Run `bash infrastructure/abox/tests/check-release-source.sh` and related course tests.
- Verify credential manifests contain references only and the rendered release bundle has no literal credentials.
- Verify Neo4j auth after rotation and MCP Pod readiness.
- Verify the course OCI artifact digest and private pull with `flux get sources oci`.
- Verify ResourceSetInputProvider, OCIRepository, and both release Kustomizations are Ready after the source cutover.
