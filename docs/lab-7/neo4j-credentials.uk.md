# Облікові дані Neo4j для навчального ABox bundle

Маніфести релізу містять лише посилання на Secret. До того як Flux встановить HelmRelease Neo4j і `neo4j-mcp`, створіть однаковий новий пароль у двох Secrets у відповідних namespace: `neo4j/neo4j-auth` (ключ `NEO4J_AUTH` має містити `neo4j/<пароль>`) і `kagent/neo4j-auth` (ключ `NEO4J_MCP_PASSWORD` містить лише пароль). Kubernetes Secrets обмежені namespace, тому потрібні обидва. Chart Neo4j читає `neo4j.passwordFromSecret`; kmcp імпортує ключі з `secretRefs` як змінні середовища.

Виконайте це у довіреній Bash-сесії з `kubectl`, налаштованим на цільовий кластер. Команда створює випадковий 256-бітний пароль у пам’яті й передає API лише base64-кодовані дані Secret; пароль не друкується та не записується у файл. Спершу вимкніть трасування команд (`set +x`).

```bash
set +x
NEO4J_PASSWORD="$(openssl rand -hex 32)"
NEO4J_AUTH_B64="$(printf 'neo4j/%s' "$NEO4J_PASSWORD" | base64 | tr -d '\n')"
NEO4J_PASSWORD_B64="$(printf '%s' "$NEO4J_PASSWORD" | base64 | tr -d '\n')"

kubectl get namespace neo4j >/dev/null 2>&1 || kubectl create namespace neo4j
kubectl get namespace kagent >/dev/null 2>&1 || kubectl create namespace kagent

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: neo4j-auth
  namespace: neo4j
type: Opaque
data:
  NEO4J_AUTH: ${NEO4J_AUTH_B64}
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: neo4j-auth
  namespace: kagent
type: Opaque
data:
  NEO4J_MCP_PASSWORD: ${NEO4J_PASSWORD_B64}
EOF

unset NEO4J_PASSWORD NEO4J_AUTH_B64 NEO4J_PASSWORD_B64
```

Не використовуйте цю процедуру первинного налаштування для ротації пароля вже ініціалізованої бази: зміна Kubernetes Secret не змінює пароль користувача у базі на постійному томі. Для наявного екземпляра спершу змініть пароль безпосередньо у Neo4j командою `ALTER CURRENT USER`, після чого узгоджено оновіть обидва namespace-local Secrets і виконайте reconcile HelmRelease/MCPServer. Не перемикайте чинне джерело Flux, доки новий артефакт і обидва Secrets не перевірені. Перед ротацією в production створіть резервну копію даних Neo4j штатним для кластера способом.

Перевірка без розкриття значень Secret:

```bash
kubectl -n neo4j get secret neo4j-auth -o go-template='{{ index .data "NEO4J_AUTH" }}' | base64 -d | cut -d/ -f1
kubectl -n kagent get secret neo4j-auth -o go-template='{{ index .data "NEO4J_MCP_PASSWORD" }}' | wc -c
```

Перша команда має вивести лише `neo4j`, друга — лише кількість байтів. Не запускайте `kubectl get secret -o yaml/json` у спільному терміналі та не комітьте згенеровані маніфести Secret.
