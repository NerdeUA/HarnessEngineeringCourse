# ABox source vendored for HarnessEngineeringCourse

This directory is the course-owned copy of ABox's `feat/llmd-embeddings` source, including the Lab 4 releases and the Lab 7 tracing setup. Keep the separate `abox/` checkout as an upstream reference only; do not commit changes there.

The release bundle is `releases/`. The course workflow publishes it to:

```text
oci://ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings:<semver>
```

The OCI tag is the numeric version from a course Git tag named `abox-vX.Y.Z`. The workflow rejects malformed tags and refuses to overwrite an existing version. It publishes no `latest` alias. Publishing is separate from editing this source: validate the source and package read access before creating/pushing a release tag.

Flux consumers need permission to read the GHCR package. Prefer making this package public if course policy allows. For a private package, provide a read-only GHCR pull secret in `flux-system` out of band; never add the credential to this repository. See `docs/lab-7/README.md` for the course migration and rollback procedure.

`releases/lab7/` contains the tested Jaeger, MLflow, and OTel Collector manifests from `docs/lab-7/manifests/`, promoted into the Flux release bundle. When changing those manifests, keep the Lab 7 instructions and configuration check aligned.
