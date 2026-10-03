# Neo4j credentials for the course ABox bundle

The release manifests contain references only. Before Flux installs the Neo4j HelmRelease and `neo4j-mcp`, create the same fresh password in two namespace-local Secrets: `neo4j/neo4j-auth` (`NEO4J_AUTH` must be `neo4j/<password>`) and `kagent/neo4j-auth` (`NEO4J_MCP_PASSWORD` must be the password alone). Kubernetes Secrets are namespace-scoped, so both are required. The Neo4j chart reads `neo4j.passwordFromSecret`; kmcp imports the `secretRefs` keys as environment variables.

Run this in a trusted Bash session with `kubectl` configured for the target cluster. It generates a random 256-bit password in memory and sends only base64-encoded Secret data to the API; it does not print or save the password. Disable shell tracing first (`set +x`).

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

Do not use this initial-install procedure to rotate an already-initialized database: changing a Secret does not change the Neo4j user's password on the persistent database. For an existing instance, first change the password inside Neo4j with `ALTER CURRENT USER`, then atomically update both namespace-local Secrets and reconcile the HelmRelease/MCPServer. Keep the current Flux release source in place until the new artifact and both Secrets are verified. Back up the Neo4j data using the cluster's normal backup procedure before a production password rotation.

Validate without revealing Secret values:

```bash
kubectl -n neo4j get secret neo4j-auth -o go-template='{{ index .data "NEO4J_AUTH" }}' | base64 -d | cut -d/ -f1
kubectl -n kagent get secret neo4j-auth -o go-template='{{ index .data "NEO4J_MCP_PASSWORD" }}' | wc -c
```

The first command should print only `neo4j`; the second prints only a byte count. Never run `kubectl get secret -o yaml/json` in a shared terminal or commit rendered Secret manifests.
