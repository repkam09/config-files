# Cluster configuration reference (`development.yaml`)

The static config file controls most server behavior. Top-level sections: `global`, `persistence`, `log`, `clusterMetadata`, `services`, `publicClient`, `archival`, `namespaceDefaults`, `dcRedirectionPolicy`, `dynamicConfigClient`.

Changing any value here requires a **process restart**. The parser lives at https://github.com/temporalio/temporal/blob/main/common/config/config.go.

## Contents

- [global](#global) - membership, metrics, pprof, tls
- [persistence](#persistence) - datastores (SQL / Cassandra), shards, visibility
- [services](#services) - frontend/matching/worker/history rpc
- [publicClient](#publicclient)
- [clusterMetadata](#clustermetadata)
- [archival / namespaceDefaults](#archival)
- [dynamicConfigClient](#dynamicconfigclient)

## global

Process-wide config. Minimal example:

```yaml
global:
  membership:
    broadcastAddress: '127.0.0.1'   # IP reachable by other hosts in the cluster (IPv4 only)
  metrics:
    prometheus:
      framework: 'tally'            # 'tally' (default) or 'opentelemetry'
      listenAddress: '127.0.0.1:8000'
```

- `membership.maxJoinDuration` - time to attempt joining the gossip layer before failing (default 10s).
- `membership.broadcastAddress` - use `127.0.0.1` for single-host; otherwise an IP other hosts can reach.
- `metrics` - supports `prometheus`, `m3`, and `statsd` (statsd is not natively supported). `excludeTags` helps drop unbounded-cardinality tags like `task_queue`.
- `pprof.port` - if set, starts pprof on that port at process start.
- `tls` - SSL/TLS for `internode` and `frontend`. Covered fully in `security-mtls.md`.

## persistence

Holds the datastore/persistence layer. Minimal Cassandra example with a separate ES visibility store:

```yaml
persistence:
  defaultStore: default
  visibilityStore: cass-visibility
  secondaryVisibilityStore: es-visibility   # optional, enables Dual Visibility
  numHistoryShards: 512                      # IMMUTABLE after first init
  datastores:
    default:
      cassandra:
        hosts: '127.0.0.1'
        keyspace: 'temporal'
        user: 'username'
        password: 'password'
    cass-visibility:
      cassandra:
        hosts: '127.0.0.1'
        keyspace: 'temporal_visibility'
    es-visibility:
      elasticsearch:
        version: 'v7'
        url:
          scheme: 'http'
          host: '127.0.0.1:9200'
        indices:
          visibility: temporal_visibility_v1_dev
```

Required top-level keys: `numHistoryShards`, `defaultStore`, `visibilityStore`. `secondaryVisibilityStore` is optional (Dual Visibility).

> `numHistoryShards` is set once when the cluster is first initialized and ignored on every run after that. Pick a value high enough for worst-case peak load up front. Changing it later requires a brand-new cluster and a migration.

### SQL datastore (PostgreSQL / MySQL)

```yaml
datastores:
  default:
    sql:
      pluginName: 'postgres'      # 'postgres' or 'mysql' (required)
      databaseName: 'temporal'    # required
      connectAddr: '127.0.0.1:5432'  # required
      connectProtocol: 'tcp'      # 'tcp' or 'unix' (required)
      user: 'temporal'
      password: 'temporal'
      maxConns: 20
      maxIdleConns: 20
      maxConnLifetime: '1h'
      # tls: { enabled: true, serverName: ..., certFile: ..., keyFile: ..., caFile: ..., enableHostVerification: true }
```

Cassandra fields: `hosts` (required, comma-separated), `port` (default 9042), `user`, `password`, `keyspace` (required), `datacenter`, `maxConns`, `tls`.

Datastore `tls` block: `enabled` (bool), `serverName`, `certFile`, `keyFile`, `caFile`, `enableHostVerification` (verify hostname + server cert; inverse of InsecureSkipVerify). For client certs, both `certFile` and `keyFile` must be present, or both omitted.

## services

Config keyed by the four service roles: `frontend`, `matching`, `worker`, `history`.

```yaml
services:
  frontend:
    rpc:
      grpcPort: 7233
      membershipPort: 6933
      bindOnIP: '0.0.0.0'
```

`rpc` keys: `grpcPort`, `membershipPort` (must differ per service; differ per cluster if multiple clusters share a network), `bindOnLocalHost` (use 127.0.0.1), `bindOnIP` (specific IP or 0.0.0.0; mutually exclusive with `bindOnLocalHost`). Port values must be consistent for a given role across all hosts.

## publicClient

Required. How background server workers reach the frontend.

```yaml
publicClient:
  hostPort: 'localhost:7233'
```

Use a `dns:///` prefix to enable round-robin across DNS-resolved IPs.

## clusterMetadata

Local cluster identity; also used by Multi-Cluster Replication.

```yaml
clusterMetadata:
  enableGlobalNamespace: true
  failoverVersionIncrement: 10
  masterClusterName: 'active'
  currentClusterName: 'active'   # IMMUTABLE after first run
  clusterInformation:
    active:
      enabled: true
      initialFailoverVersion: 0
      rpcAddress: '127.0.0.1:7233'
```

## archival

Optional. Moves closed workflow histories and visibility records to blob storage (`filestore`, `gstorage`, `s3`, or custom). Set cluster-level `archival.history`/`archival.visibility` `state: enabled` plus `enableRead`, and provide `namespaceDefaults.archival` URIs. To disable, set all `state: disabled` and `enableRead: false`. Details: https://docs.temporal.io/self-hosted-guide/archival.

## dynamicConfigClient

Wires file-based dynamic configuration (runtime-tunable values).

```yaml
dynamicConfigClient:
  filepath: 'config/dynamicconfig/development-sql.yaml'
  pollInterval: '10s'   # minimum 5s
```

Full dynamic config key list: https://docs.temporal.io/references/dynamic-configuration.

## dcRedirectionPolicy

Optional frontend cross-DC API redirection: `policy` is `noop` (default), `selected-apis-forwarding`, or `all-apis-forwarding`.
