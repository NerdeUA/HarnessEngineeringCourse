# Official Qdrant MCP deployment notes

This local kind cluster runs the upstream `mcp-server-qdrant` package pinned to v0.8.1. The original cached image had corrupted Python package contents, so the replacement image is built locally and is not available from a remote registry.

From the course repository root:

```sh
docker build -t qdrant-mcp-official:0.8.1-rebuilt \
  -f docs/lab-4/official-mcp/Dockerfile docs/lab-4/official-mcp
kind load docker-image qdrant-mcp-official:0.8.1-rebuilt --name abox
kubectl apply -f docs/lab-4/official-mcp/kagent-resources.yaml
kubectl rollout status deployment/qdrant-minilm -n kagent --timeout=180s
```

The eight indexed records are live Qdrant data, not part of this manifest. To recreate the comparison corpus, call `qdrant-store` on this MCP and `vector_store` on the ABox baseline with identical information and metadata. Do not use the MiniLM and Nomic embeddings in the same collection: their vector dimensions differ (384 vs. 768).
