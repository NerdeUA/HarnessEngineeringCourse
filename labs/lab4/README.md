# Lab 4 — Qdrant MCP retrieval comparison

The release source is `feat/llmd-embeddings`, OCI artifact
`oci://ghcr.io/den-vasyliev/abox/releases-llmd-embeddings:0.9.5`.

The branch supplies the baseline `retrieval-agent` and `qdrant-mcp`. The
course-owned overlay adds the official Qdrant MCP as `qdrant-minilm` and an
isolated `retrieval-agent-official` that uses only `qdrant-store` and
`qdrant-find`.

| Setup | MCP | Embedding model | Collection |
|---|---|---|---|
| Baseline | abox `qdrant-mcp` | nomic-embed-text-v1.5 through llama.cpp | `abox-nomic` |
| Official | Qdrant `mcp-server-qdrant` 0.8.1 | `sentence-transformers/all-MiniLM-L6-v2` via FastEmbed | `abox-minilm` |

The separate collections are required because vectors from different models
are not comparable. The upstream container defaults to SSE, while kagent's
`MCPServer` stdio transport expects a stdio process; the Dockerfile here pins
the official package and starts its stdio console entry point.

## Execution status

The release, official MCP resource, and `retrieval-agent-official` were
reconciled in the existing `abox` cluster. The local image was built and
loaded, the MCP pod reached `Running`, and the agent reported `Ready`. The
indexing and comparison runs were not completed: etcd subsequently logged a
fatal Raft state I/O error and the Kubernetes API began returning EOF. The
cluster was left intact; no restart or recreation was attempted. Accordingly,
the evaluation below remains pending and contains no invented scores.

## Build and deploy the official MCP

From the course repository root, with the existing `abox` KinD cluster active:

```bash
docker build -t qdrant-mcp-official:0.8.1 -f labs/lab4/Dockerfile labs/lab4
kind load docker-image qdrant-mcp-official:0.8.1 --name abox
kubectl apply -f labs/lab4/manifests/qdrant-mcp-official.yaml
kubectl get mcpserver,agent -n kagent
```

The model is downloaded by FastEmbed on first use. Allow that first ingest to
finish before starting the timed evaluation.

## Evaluation protocol

Use the exact same corpus and question set for both agents. Index once through
the baseline `retrieval-agent` and once through `retrieval-agent-official`.
Record the returned source IDs, whether the expected object appeared in the
top 5, whether the answer was supported by the retrieved text, and elapsed
time. Do not reuse a collection across embedding backends.

The corpus, prompt, raw agent outputs, and measured scores belong in
`corpus/` and `evaluation.md`; keep API keys and Kubernetes Secret values out
of this repository.
