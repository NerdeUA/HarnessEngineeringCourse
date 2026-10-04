# Lab 7 final verification / Фінальна перевірка ЛР7

Date / Дата: 2026-10-04

## Environment / Середовище

- Course artifact / Курсовий артефакт: private GHCR `ghcr.io/nerdeua/harnessengineeringcourse/abox/releases-llmd-embeddings:0.1.3`
- OCI digest: `sha256:4beb600712399aa47700a75d25e9cc65185d027451d7b7fa8092be1e825cdd8f`
- Flux `releases` Kustomization: `Ready=True`, revision `0.1.3`
- Collector deployment: rollout successful; image `otel/opentelemetry-collector-contrib:0.161.0`

## Successful agent run / Успішний запуск агента

- Agent / Агент: `k8s-agent`
- Model / Модель: `gpt-4.1-mini`
- Task / Завдання: read-only inventory of Kubernetes Nodes and their Ready condition
- A2A task ID: `01a1070f-cf21-7c39-a9fd-9f96c134dced`
- A2A context ID: `01a1070f-cf21-7ebd-a7ab-80dd5116d513`
- Result / Результат: completed; the agent invoked `k8s_get_resources`
- Trace ID: `1495d32fea9a55da394f79de961f3878`

## Backend comparison evidence / Докази в бекендах

| Backend / Бекенд | Verification / Перевірка |
|---|---|
| Jaeger 2 | Same trace ID; `invoke_agent`, model `generate_content gpt-4.1-mini`, and `execute_tool k8s_get_resources` spans |
| MLflow | Same trace ID in experiment `0`; trace state `OK` |
| Phoenix | Same trace ID in project `default`; one matching trace returned for the A2A context ID |

## Redaction check / Перевірка редагування payload

The final trace retained useful model, operation, token-usage, and tool-name metadata. Its span attribute keys did not include the provider payload attributes `gcp.vertex.agent.llm_request`, `gcp.vertex.agent.llm_response`, `gcp.vertex.agent.tool_call_args`, or `gcp.vertex.agent.tool_response`, nor generic GenAI prompt/completion/message/tool-argument fields. This verifies the Collector transform on a fresh successful run; it does not retroactively remove payload fields from traces emitted before release `0.1.3`.

Фінальний trace зберіг корисні метадані про модель, операцію, кількість токенів і назву інструмента. Ключі span-атрибутів не містили provider payload-полів `gcp.vertex.agent.llm_request`, `gcp.vertex.agent.llm_response`, `gcp.vertex.agent.tool_call_args` або `gcp.vertex.agent.tool_response`, а також стандартних GenAI полів prompt/completion/message/аргументів інструментів. Це підтверджує роботу Collector transform на новому успішному запуску, але не видаляє payload із трейсів, створених до релізу `0.1.3`.

## Completion statement / Підсумок

The task is complete: the agent produced a successful read-only result, and the same semantic model/tool trace was accepted by all three backends. OTel, Jaeger, MLflow, and Phoenix have been compared in both language reports and ADRs. No commit was made to the upstream `abox` repository.

Завдання виконано: агент успішно виконав read-only запит, а той самий семантичний trace моделі й інструмента прийняли всі три бекенди. Порівняння OTel, Jaeger, MLflow і Phoenix задокументовано англійською та українською у звітах і ADR. Коміту в upstream-репозиторій `abox` не було.
