# HarnessEngineeringCourse

## Course-owned ABox source

The ABox release source used for the certificate labs is maintained in [`infrastructure/abox/`](infrastructure/abox/). The sibling `abox/` checkout is an upstream reference; course changes and commits belong in this repository.

The vendored source preserves the deployed `feat/llmd-embeddings` release and includes the tested Lab 7 backends and tracing settings. The course's OpenTofu bootstrap defaults to `oci://ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings`; it does not follow the upstream ABox OCI package.

Release and migration details, GHCR read-access requirements, and rollback guidance are in [`infrastructure/abox/README.md`](infrastructure/abox/README.md) and [`docs/lab-7/README.md`](docs/lab-7/README.md). Publishing requires an explicit `abox-vX.Y.Z` Git tag and a successful source/configuration review. Verify the GHCR package is readable by the cluster before moving the live Flux ResourceSet input.
