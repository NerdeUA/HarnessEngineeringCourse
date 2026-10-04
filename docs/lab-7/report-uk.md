# Звіт ЛР7 — OpenTelemetry, MLflow і Phoenix

Дата: 2026-10-04. Середовище: ABox Kubernetes, kagent `0.10.1`, OpenTelemetry Collector contrib `0.161.0`, Jaeger `2.21.0`, MLflow `3.11.1`, Phoenix `12.0.10`.

## Виконано

- Розгорнуто та налаштовано Jaeger, MLflow, Phoenix і один OpenTelemetry Collector. Collector приймає OTLP/gRPC та експортує дані до Jaeger (OTLP/gRPC), MLflow (OTLP/HTTP, experiment `0`) і Phoenix (OTLP/HTTP з API key із Kubernetes Secret).
- Збережено конфігурацію у курсовому ABox bundle; опубліковано приватний OCI-артефакт `0.1.3` і синхронізовано його через Flux (`Ready=True`). Коміту в upstream-репозиторій `abox` не було.
- Залишено `captureSensitiveContent: false` та додано Collector-side видалення payload-атрибутів запитів/відповідей моделі, вхідних/вихідних даних інструментів і стандартних GenAI prompt/completion полів. Після зміни ConfigMap Collector перезапущено та перевірено успішний rollout.
- Надіслано read-only A2A-запит до `k8s-agent`. Агент успішно завершив завдання, викликав `k8s_get_resources` і повернув назви трьох Kubernetes Node та їх Ready condition.
- Той самий trace `1495d32fea9a55da394f79de961f3878` знайдено у Jaeger, experiment `0` у MLflow та проєкті `default` у Phoenix.

## Порівняння

| Рішення | Доказ із того самого запуску | Сильна сторона для GenAI | Виявлене обмеження |
|---|---|---|---|
| OpenTelemetry + Collector | Один OTLP-вхід; transform/redaction перед fan-out до трьох експортерів | Відкрита інструментація, централізована обробка та незалежні призначення | Сам по собі OTel — стандарт і конвеєр, а не UI аналізу чи довготривале сховище |
| Jaeger 2 | Той самий trace містить `invoke_agent`, span-и моделі `gpt-4.1-mini` і `execute_tool k8s_get_resources`; payload-полів немає | Зрозуміла часова шкала span-ів і зв'язків сервісів | Демо-сховище в пам'яті; обмежений workflow GenAI експериментів/оцінювання |
| MLflow Tracing | Той самий trace ID знайдено в experiment `0`, стан `OK` | Зручне поєднання трейсів з експериментами й оцінюванням | Організація навколо експериментів; у кластері — демонстраційний SQLite з одним worker |
| Phoenix | Той самий trace ID знайдено у проєкті `default` | Спеціалізований LLM trace/project інтерфейс та GenAI-аналіз | Для OTLP ingest потрібен чинний system API key; необхідно керувати розгортанням і retention |

## Спостереження й обмеження

Однаковий trace ID у трьох бекендах підтверджує наскрізний експорт і ingest для одного успішного запуску агента. Семантичні span-и моделі й інструмента дають більше контексту, ніж лише trace контролера. Це порівняння спостережуваності, а не статистичне чи людське оцінювання якості відповіді.

Важливе зауваження щодо приватності: одного `captureSensitiveContent: false` виявилося недостатньо — деякі сирі payload-атрибути запиту/відповіді/інструментів `gcp.vertex.agent.*` усе одно потрапляли у trace. Тепер курсовий Collector transform видаляє ці атрибути та відповідні стандартні GenAI payload-ключі перед fan-out. Фінальний trace зберігає метадані про модель, операцію, кількість токенів та інструмент, але не містить перевірених сирих payload-ключів.

Раніше експортовані трейси до redaction залишаються у сховищах і мають вважатися чутливими. У межах цієї роботи історичні записи не очищалися. Jaeger зберігає дані в пам'яті; MLflow використовує SQLite та PVC; Phoenix — налаштовану для нього базу даних. Якщо старі дані потрібно видалити, застосуйте retention/deletion процедури кожного бекенду. Конфігурація Collector змонтована через ConfigMap `subPath`; майбутня зміна ConfigMap потребує restart rollout Collector, оскільки автоматичного перезапуску тут немає.

## Висновок

ЛР7 завершена: усі три рішення отримали один і той самий успішний trace агента, а їхні відмінності задокументовано. OTel/Collector — спільний транспорт і рівень політик; Jaeger — загальний розподілений tracing; MLflow — трейсинг у контексті експериментів; Phoenix — аналіз LLM-трейсів і проєктів. Докази та інструкції наведені у [README ЛР7](README.md), [ADR](ADR-lab-7-uk.md) і [фінальній перевірці](evidence/final-verification.md).
