# ADR — Official Qdrant MCP and MiniLM for the Lab 4 comparison

- Status: accepted for the certificate experiment; retrieval quality remains
  pending measured agent runs.
- Date: 2026-10-02.

## Context

The `feat/llmd-embeddings` release includes a custom Go Qdrant MCP using
llama.cpp and nomic-embed-text-v1.5. Lab 4 separately requires the official
Qdrant MCP, `sentence-transformers/all-MiniLM-L6-v2`, the same corpus indexed
through both MCP toolsets, and an agentic retrieval comparison.

The official MCP repository currently documents `qdrant-store` and
`qdrant-find`, uses FastEmbed, and defaults to MiniLM. Its upstream container
starts an SSE server; the kagent `MCPServer` integration used in this cluster
is stdio-based.

## Decision

Build a small course-owned image from the official PyPI package pinned to
`mcp-server-qdrant==0.8.1`, with the official stdio console entry point.
Deploy it as a separate `MCPServer` named `qdrant-minilm`; use a separate
`retrieval-agent-official` with only `qdrant-store` and `qdrant-find`.

Keep the branch's default MCP and `retrieval-agent` as the baseline. Use
collections `abox-minilm` and `abox-nomic` respectively. Both agents share
`default-model-config` and the same `k8s-agent` delegate.

## Consequences

- The comparison isolates two end-to-end retrieval configurations: official
  MCP + MiniLM/FastEmbed versus the branch's MCP + nomic/llama.cpp. It does
  not isolate embedding model quality from MCP implementation/tool semantics.
- Collections remain model-specific; copying vectors between them is invalid.
- The official model is downloaded on first ingest, which affects first-call
  latency and requires registry/network egress from the pod.
- The Docker image is local to the KinD cluster and is not published to GHCR.
- No quality conclusion is accepted until the same corpus and fixed query set
  have been run through both agents and raw outputs are recorded.

## References

- [Official Qdrant MCP server](https://github.com/qdrant/mcp-server-qdrant)
- [Official Qdrant MCP Dockerfile](https://raw.githubusercontent.com/qdrant/mcp-server-qdrant/master/Dockerfile)
- [Official Qdrant MCP package metadata](https://raw.githubusercontent.com/qdrant/mcp-server-qdrant/master/pyproject.toml)
