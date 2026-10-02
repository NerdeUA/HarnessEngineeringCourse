FROM python:3.11-slim@sha256:bab1b7ef4b450c81002278d035eff85ebe394ae94df904f7a3ba14f7e16e487b

WORKDIR /app

RUN pip install --no-cache-dir uv \
    && uv pip install --system --no-cache-dir \
       mcp-server-qdrant==0.8.1 \
       fastmcp==2.7.0 \
       'pydantic<2.12'

ENV COLLECTION_NAME=abox-minilm \
    EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2

ENTRYPOINT ["mcp-server-qdrant"]
