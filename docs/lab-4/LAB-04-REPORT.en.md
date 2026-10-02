# Lab 4 — Deployment and retrieval evaluation report

**Run date:** 2026-10-02; **cluster:** local kind `abox`, Kubernetes v1.35.0, three Ready nodes; **release artifact:** Flux `OCIRepository/releases`, `oci://ghcr.io/den-vasyliev/abox/releases-llmd-embeddings`, revision `0.9.5`.
**Result:** deployment, MCP wiring, dual indexing, and vector-level comparison complete; end-to-end agent generation is blocked by the invalid configured OpenAI key.

## Completion by requirement

| Lab requirement | Result / evidence |
|---|---|
| Deploy `feat/llmd-embeddings` release | Done. Flux reports the `releases-llmd-embeddings` OCI artifact at revision `0.9.5`; embedding and llm-d workloads are present. All three nodes are Ready. |
| Add the official Qdrant MCP | Done. `kagent/qdrant-minilm` runs official `mcp-server-qdrant` v0.8.1; MCP handshake and `tools/list` succeed. A corrupted pre-existing image was replaced by a locally rebuilt image. |
| Configure model for `retrieval-agent` and `k8s-agent` | Done. Both use `kagent/default-model-config` (`OpenAI`, `gpt-4.1-mini`). |
| Add official Qdrant tools | Done. Official MCP lists `qdrant-store` and `qdrant-find`; `retrieval-agent-official` references those tools. Baseline `retrieval-agent` uses `vector_store` and `vector_find`. |
| Set system prompt | Done. Official agent is limited to the indexed corpus and `abox-minilm`, retains source metadata, and must not mix baseline collection results. |
| Index with MiniLM | Done. Eight records in `abox-minilm`; Qdrant reports 384 dimensions. |
| Index the same corpus with default Qdrant MCP | Done. The same eight record texts and metadata were stored using `vector_store` in `abox-nomic`; Qdrant reports 768 dimensions. |
| Compare and record results in ADR | Vector-retrieval comparison done and recorded in the paired ADRs. Full agent-level generation comparison is pending valid OpenAI credentials (see below). |

## Corpus and method

The corpus contains eight descriptions derived from live declared cluster objects: the Qdrant Service and StatefulSet, `default-model-config`, `k8s-agent`, both retrieval agents, and both MCPServer configurations. Each record has the same text and `source`, `kind`, `namespace`, and `name` metadata in both collections. Records were inserted using each MCP's own storage tool. No generated Pods, Secrets, or controller-created objects were indexed.

Four fixed questions were sent to each MCP's retrieval tool. Rank is the position of the expected object in the MCP response; the comparison uses the first relevant rank for the final query, where both agent records are relevant. Scores are reported as Hit@k and mean reciprocal rank (MRR), not as LLM answer quality.

| Query | Expected record(s) | MiniLM rank | Baseline rank |
|---|---|---:|---:|
| Which Kubernetes Service exposes the Qdrant HTTP REST API and what is the port? | `Service/qdrant` | 2 | 1 |
| Which embedding model and collection are configured for the official Qdrant MCP server? | `MCPServer/qdrant-minilm` | 2 | 1 |
| Which Kubernetes agent has tools for reading pod logs and checking service connectivity? | `Agent/k8s-agent` | 1 | 1 |
| How do the baseline and official retrieval agents differ in MCP tool names and vector collections? | `Agent/retrieval-agent`, `Agent/retrieval-agent-official` | 1, 2 | 1, 2 |

| Metric | Official MiniLM | ABox baseline |
|---|---:|---:|
| Hit@1 (first relevant record per query) | 2/4 | 4/4 |
| Hit@3 | 4/4 | 4/4 |
| MRR | 0.75 | 1.00 |

The Qdrant collections each contain eight points. `indexed_vectors_count` is zero because the small corpus is below the default HNSW indexing threshold; Qdrant still serves the tested searches by full scan. The live collection configs show a named 384-dimensional MiniLM vector and a 768-dimensional baseline vector.

## Agent-level test and blocker

The baseline agent was invoked through the kagent A2A endpoint. The endpoint returned HTTP 200, but the task failed before producing an answer: the configured OpenAI provider returned `401 Unauthorized` with error code `invalid_api_key`. The error message was sanitized by the provider; no Kubernetes Secret contents were read. Since the official and baseline agents share `default-model-config`, running more agent calls cannot produce a valid comparison until the existing `kagent/kagent-openai` Secret contains a working key.

Therefore this report distinguishes two outcomes: the MCP servers and retrieval tools were exercised successfully on identical indexed data; LLM-driven agent selection, grounded answer correctness, and latency/cost comparison remain unverified. Once credentials are corrected, rerun the same four prompts against both agents and append the answer/tool traces to this report.

## Operational note: rebuilt official image

The worker's cached `qdrant-mcp-official:0.8.1` image contained an all-null Pygments mapping file, and Python exited with `SyntaxError: source code string cannot contain null bytes`. A fresh image was built with official package `mcp-server-qdrant==0.8.1`, import-tested, and loaded into the three kind nodes as `qdrant-mcp-official:0.8.1-rebuilt`. The CRD now points to that local tag. The tag is not published to a registry, so a recreated cluster must build/load it first. Upstream documents building the official Docker image in its [repository](https://github.com/qdrant/mcp-server-qdrant); the [v0.8.1 release](https://github.com/qdrant/mcp-server-qdrant/releases/tag/v0.8.1) is the package version used here.

## Submission evidence

The paired ADRs and [terminal recording](lab4.cast) are in this directory. Hosted evidence: [unlisted asciinema recording](https://asciinema.org/a/QmbBaIj2QBSTCgqa). Anonymous uploads are deleted after 7 days; the local cast remains available. It contains no API keys or Secret output.
