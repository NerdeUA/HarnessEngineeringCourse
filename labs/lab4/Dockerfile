FROM python:3.11-slim

RUN pip install --no-cache-dir uv \
    && uv pip install --system --no-cache-dir mcp-server-qdrant==0.8.1

# kagent MCPServer uses stdio. The upstream container defaults to SSE, so this
# course image keeps the official package and starts its stdio entry point.
ENTRYPOINT ["mcp-server-qdrant"]
