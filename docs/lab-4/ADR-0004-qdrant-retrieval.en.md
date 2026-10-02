# ADR-0004: Compare the official Qdrant MCP with the ABox retrieval MCP

- Status: Accepted for deployment and vector-retrieval evaluation; end-to-end agent evaluation pending valid LLM credentials
- Date: 2026-10-02
- Decision owners: Course participant

## Context

Lab 4 asks for the `feat/llmd-embeddings` ABox release, Qdrant's official MCP server, configured `retrieval-agent` and `k8s-agent`, indexing the same Kubernetes corpus with `sentence-transformers/all-MiniLM-L6-v2` and with the default Qdrant MCP, and a comparison recorded in an ADR.

The cluster already had the ABox MCP using a local llama.cpp Nomic embeddings endpoint. It needed to remain available as the baseline while the official MCP used an isolated collection. Reusing one collection would be invalid: the live Qdrant configuration reports 768-dimensional baseline vectors and 384-dimensional MiniLM vectors.

## Decision

Keep two independent embedding/retrieval paths in the same Qdrant service:

| Path | MCP implementation and tools | Embedding | Collection |
|---|---|---|---|
| Baseline | ABox `qdrant-mcp`; `vector_store`, `vector_find` | llama.cpp Nomic endpoint (`llama-cpp-embeddings.llama-cpp:8090`) | `abox-nomic` (768 dimensions) |
| Comparison | Official `qdrant/mcp-server-qdrant` v0.8.1; `qdrant-store`, `qdrant-find` | `sentence-transformers/all-MiniLM-L6-v2` | `abox-minilm` (384 dimensions) |

Both `retrieval-agent` and `retrieval-agent-official` use the existing `default-model-config` (`OpenAI/gpt-4.1-mini`). `k8s-agent` remains the source of declared Kubernetes manifests. The official retrieval agent is restricted by its system prompt to the official MCP and `abox-minilm`; it must not mix results from the baseline collection. Each indexed payload includes `source`, `kind`, `namespace`, and `name` metadata.

The official image initially present on the worker was unusable: its Pygments `_mapping.py` consisted entirely of null bytes, causing `SyntaxError` while importing the official server. A fresh local image was built with the official `mcp-server-qdrant==0.8.1` package and smoke-tested, then loaded into kind under `qdrant-mcp-official:0.8.1-rebuilt`. The old image was left intact. The running MCP resource now exposes the rebuilt tag.

## Evaluation and outcome

Eight identical Kubernetes/ABox configuration records were stored via each MCP's own store tool. Qdrant reports eight points per collection; baseline vectors are 768-dimensional and MiniLM vectors are 384-dimensional. Four fixed semantic queries were run through each MCP's find tool. On this small corpus:

- Baseline: target at rank 1 for all four queries; Hit@1 4/4; Hit@3 4/4; MRR 1.00.
- MiniLM: target at rank 2 for the Qdrant Service and official MCP queries, and rank 1 for the `k8s-agent` and agent-comparison queries; Hit@1 2/4; Hit@3 4/4; MRR 0.75.

This is a retrieval-level result, not a statistically meaningful model ranking. The corpus is tiny, curated, and contains semantically overlapping descriptions; it is sufficient to verify separate indexing and tool behavior, not to conclude that one embedding model is generally superior.

The A2A agent-generation test was attempted. The controller returned HTTP 200 with a failed task whose model error was `401 Unauthorized` / `invalid_api_key`. Both retrieval agents reference the same `default-model-config`; therefore LLM-generated answers and tool-selection behavior could not be compared. No key value was read or recorded.

## Consequences

- Separate collections make vector dimensions explicit and prevent incompatible embeddings from being mixed.
- The official MCP tools and retrieval-agent prompt are live and can be exercised independently of the model provider.
- The rebuilt image is local to this kind cluster; the tag is not a published registry image. A fresh cluster must build/load it before deploying the MCP resource.
- A valid OpenAI key is needed to finish the agentic/A2A portion. The present 8-query vector benchmark is evidence for Lab 4's indexing and retrieval comparison, but does not substitute for that final agent-level comparison.

## References

- [Official Qdrant MCP repository](https://github.com/qdrant/mcp-server-qdrant)
- [Official Qdrant MCP v0.8.1 release](https://github.com/qdrant/mcp-server-qdrant/releases/tag/v0.8.1)
- [MiniLM model card](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)
