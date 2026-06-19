# Deployment and local hosting

Covers how to run a self-hosted Temporal Service: local dev server, Docker Compose, and server binaries. Temporal Cloud is out of scope.

## Decision: do you even need a production service?

If you are still developing and testing locally, you almost certainly do not need a full deployment. The CLI dev server is the recommended local option regardless of where you ship later. Reach for Docker Compose, binaries, or Kubernetes only for sustained workloads beyond what the dev server is meant to handle.

A real deployment always needs an external **datastore** (PostgreSQL, MySQL, or Apache Cassandra) for persistence, and optionally **Elasticsearch** for advanced Visibility (list/filter/search of workflow executions).

> Security note: in self-hosted deployments the Temporal Service is a critical control and persistence component. Secure it like a database. Run it on hosts that are not reachable from the public internet and restrict access to trusted internal networks.

## Local development: `temporal server start-dev`

A single binary with no external dependencies. Starts a complete Temporal Service plus Web UI on your machine. Persistence is in-memory by default (executions are lost on process exit) unless you point it at a SQLite file.

```bash
# Basic: Web UI at http://localhost:8233, frontend gRPC at localhost:7233
temporal server start-dev

# Persist across restarts using a local SQLite file
temporal server start-dev --db-filename ./temporal.db

# Custom ports
temporal server start-dev --port 7000 --ui-port 3000

# Pre-create namespaces and register search attributes
temporal server start-dev \
  --namespace my-app \
  --search-attribute OrderId=Keyword

# Override dynamic config values inline
temporal server start-dev --dynamic-config-value frontend.enableUpdateWorkflowExecution=true
```

Useful flags: `--db-filename`/`-f`, `--port`/`-p`, `--ui-port`, `--ip`, `--headless` (disable Web UI), `--namespace`/`-n`, `--search-attribute`, `--dynamic-config-value`, `--sqlite-pragma`, `--ui-codec-endpoint`, `--log-config`.

The dev server intentionally skips certain HTTP security checks to keep local use simple, and prints a warning to that effect. Never run it in production.

### Installing the CLI

```bash
# macOS
brew install temporal
```

For Linux/Windows, download the latest archive from `https://temporal.download/cli/archive/latest?platform=<os>&arch=<amd64|arm64>`, extract it, and put the `temporal` binary on your PATH.

### Embedded / in-process server

For Go integration tests you can run Temporal in-process as a library (the embedded server) instead of shelling out. See https://docs.temporal.io/self-hosted-guide/embedded-server. For non-Go SDKs (including TypeScript/Node), drive the CLI dev server from your test harness instead.

## Docker Compose

The fastest way to stand up a self-hosted-style stack (server + datastore + Web UI).

```bash
# Official quickstart stack (Postgres + Elasticsearch by default, frontend on 7233, UI on 8080)
git clone https://github.com/temporalio/docker-compose.git
cd docker-compose
docker compose up
```

The repo ships alternate compose files for different databases, visibility stores, and **TLS-enabled** configurations. Pick the one matching your target setup, e.g.:

```bash
docker compose -f docker-compose-mysql.yml up
docker compose -f docker-compose-postgres.yml up
```

The Temporal-published security/TLS sample stacks live in `temporalio/samples-server` under `compose/` (clone that repo and `cd samples-server/compose`), which is the canonical place for mTLS-enabled compose examples.

### Enabling SSO in the Web UI

The UI container reads SSO settings from environment variables. No extra config file needed, which makes it ideal for containerized setups:

```yaml
temporal-ui:
  image: temporalio/ui:latest
  depends_on:
    - temporal
  environment:
    - TEMPORAL_ADDRESS=temporal:7233
    - TEMPORAL_GRPC_ENDPOINT=temporal:7233
    - TEMPORAL_AUTH_ENABLED=true
    - TEMPORAL_AUTH_PROVIDER_URL=https://your-idp.example.com
    - TEMPORAL_AUTH_CLIENT_ID=xxxxxxxx
    - TEMPORAL_AUTH_CLIENT_SECRET=xxxxxxxx
    - TEMPORAL_AUTH_CALLBACK_URL=https://your-domain/auth/sso/callback
    - TEMPORAL_AUTH_SCOPES=openid profile email
  ports:
    - 8080:8080
```

Values map to your OAuth/OIDC identity provider (Google, Auth0, Okta, etc.). UI auth is separate from server-side API authorization; configure both.

## Server binaries + systemd

A full service is two Go binaries: the core Temporal Server (`temporalio/temporal` releases) and the Temporal UI Server (`temporalio/ui-server` releases). Each can be deployed separately and managed with `systemd`. Run behind an Nginx or Envoy reverse proxy if you need an edge. See the Temporal infrastructure tutorials at https://learn.temporal.io/tutorials/infrastructure/.

### Configuration templating

The server renders a config template into the final `config.yaml` at startup, filling values from environment variables (DB endpoints, TLS paths, feature flags) so one template works across environments. Notes:

- Templates are rendered with embedded `sprig`; old `dockerize`-specific helpers will fail.
- `.Env` and `default` function usage differs from older setups.
- Validate with `temporal-server render-config` before deploying.
- If you skip custom templating, the default config is rendered automatically and embedded in the binary.

## Kubernetes / Helm (pointer)

Production scale typically uses the official Helm charts (`temporalio/helm-charts`). This skill's deep dives target Docker Compose and local dev per the intended scope, but the authorization reference includes a Helm `values` snippet for shipping a *custom* server image (one with your ClaimMapper/Authorizer compiled in). When deploying with Helm charts 0.73.1+, some image-related config options may need adjustment.

## Where configuration lives

- **Static cluster config**: the `development.yaml` file (persistence, services, TLS, etc.). Editing it requires a process restart. Full reference: `configuration.md`.
- **Dynamic config**: a separate YAML polled at runtime (min poll interval 5s), pointed to via `dynamicConfigClient` in the static config. Use this for values you want to tune without restarting.
