# Lab 4 retrieval evaluation

## Environment

- ABox release: `feat/llmd-embeddings`, artifact tag `0.9.5`
- Default collection: `abox-nomic`
- Official collection: `abox-minilm`
- Agent model configuration: `default-model-config`
- Corpus revision: pending
- Runtime status: official MCP pod reached `Running`; kagent then lost API
  access after etcd fatal I/O error. No indexing/query samples were captured.

## Fixed corpus and questions

Record each corpus item in `corpus/` with a stable source ID. Use the same
items and the same query wording for both configurations.

| Query ID | Question | Expected source IDs | Baseline top 5 / support | Official top 5 / support | Latency |
|---|---|---|---|---|---|
| Q1 | Which gateway listener accepts routes from every namespace? | pending | pending | pending | pending |
| Q2 | Which kagent model configuration does the retrieval agent use? | pending | pending | pending | pending |
| Q3 | Which service exposes the nomic embeddings endpoint, and on what port? | pending | pending | pending | pending |
| Q4 | Which Qdrant collection is used by the default MCP? | pending | pending | pending | pending |
| Q5 | Which release owns the order of CRD and application reconciliation? | pending | pending | pending | pending |

## Observations

Not yet evaluated. Fill in raw answers and retrieved source IDs before
calculating recall@5 or making a quality claim. Record first-call latency
separately because FastEmbed downloads/initializes MiniLM on first use. Resume
only after safely restoring API/etcd health.

## Result

Pending live indexing and agent runs.
