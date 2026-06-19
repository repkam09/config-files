# TLS / mTLS for self-hosted Temporal

mTLS encrypts traffic and (optionally) authenticates callers at the transport layer. It is configured under `global.tls` in the cluster config. It is independent from authorization (ClaimMapper/Authorizer in `authorization.md`): mTLS answers "is this connection encrypted and is the peer's cert trusted", not "is this caller allowed to do X".

Self-signed or properly minted certificates both work. Sample TLS stacks: https://github.com/temporalio/samples-server/tree/main/tls.

## The two sections, and the two halves

`global.tls` splits into two scopes so you can use different certs/settings for each:

- **`internode`** - encrypts traffic *between* Temporal services (frontend, matching, history, worker).
- **`frontend`** - encrypts the frontend's public endpoints, i.e. SDK clients/workers talking to the server.

Each scope has a `server` half and a `client` half:

- `server` - `certFile`, `keyFile`, `requireClientAuth` (bool; true = mutual TLS), `clientCaFiles` (CAs trusted for client certs; ignored unless `requireClientAuth`).
- `client` - `serverName` (expected DNS SubjectName in the presented server cert), `rootCaFiles` (CAs to trust for the server cert when the host doesn't already trust them).

## Why `serverName` is almost always required

Temporal services communicate IP-to-IP. TLS hostname verification expects a DNS name, so the `client` section generally must set `serverName` to the DNS SAN present in the server certificate. You can omit it only if your server certs carry the appropriate **IP** Subject Alternative Names. A mismatched or missing `serverName` is the most common reason an otherwise-correct mTLS setup fails to connect.

## Example: server TLS on the frontend only (encryption, no client auth)

```yaml
global:
  tls:
    frontend:
      server:
        certFile: /path/to/cert/file
        keyFile: /path/to/key/file
      client:
        serverName: dnsSanInFrontendCertificate
```

Add `rootCaFiles` to the client section when the client host does not already trust the server's root CA:

```yaml
global:
  tls:
    frontend:
      server:
        certFile: /path/to/cert/file
        keyFile: /path/to/key/file
      client:
        serverName: dnsSanInFrontendCertificate
        rootCaFiles:
          - /path/to/frontend/server/CA/files
```

## Example: fully secured cluster (mutual TLS, internode + frontend)

```yaml
global:
  tls:
    internode:
      server:
        certFile: /path/to/internode/cert/file
        keyFile: /path/to/internode/key/file
        requireClientAuth: true
        clientCaFiles:
          - /path/to/internode/serverCa
      client:
        serverName: dnsSanInInternodeCertificate
        rootCaFiles:
          - /path/to/internode/serverCa
    frontend:
      server:
        certFile: /path/to/frontend/cert/file
        keyFile: /path/to/frontend/key/file
        requireClientAuth: true
        clientCaFiles:
          - /path/to/internode/serverCa
          - /path/to/sdkClientPool1/ca
          - /path/to/sdkClientPool2/ca
      client:
        serverName: dnsSanInFrontendCertificate
        rootCaFiles:
          - /path/to/frontend/serverCa
```

## Certificate requirements and the EKU gotcha

When `requireClientAuth` is enabled, the `internode.server` certificate doubles as the *client* certificate that services present to each other. That creates rules people miss:

- The `internode.server` certificate must be specified on **all** roles, even a frontend-only config.
- Internode server certs must be minted with **either no Extended Key Usages, or both ServerAuth and ClientAuth EKUs**. A ServerAuth-only cert will break internode mutual TLS.
- If your CAs are untrusted (self-signed/private), the internode server CA must appear in all three of these places:
  - `internode.server.clientCaFiles`
  - `internode.client.rootCaFiles`
  - `frontend.server.clientCaFiles`

## Restricting which clients may connect

Set `requireClientAuth: true` and list the CA(s) that issued your clients' certs in `clientCaFiles` (in `internode` and/or `frontend`). Only clients presenting a cert chaining to a listed CA may connect. This is transport-level access control; for per-user/per-namespace permissions you still need an Authorizer.

## Anti-spoofing

`serverName` in the `client` section also defends against MITM/spoofing: it forces the connection to verify that the server cert's CN/SAN matches the expected name.

## Connecting a TypeScript / Node client and worker over mTLS

On the client side you supply the client cert/key and (if needed) the server's CA. Both the `Connection` (client) and `NativeConnection` (worker) accept the same TLS options.

```typescript
import { Connection, Client } from '@temporalio/client';
import { NativeConnection, Worker } from '@temporalio/worker';
import fs from 'fs/promises';

const tls = {
  // Override the SNI / target name used for hostname verification.
  // Set this to the DNS SAN in the server cert when connecting by IP.
  serverNameOverride: 'dnsSanInFrontendCertificate',
  // The CA that signed the server's cert (omit if already trusted by the host).
  serverRootCACertificate: await fs.readFile('/path/to/frontend/serverCa.pem'),
  // The client's own cert + key (required when the server sets requireClientAuth).
  clientCertPair: {
    crt: await fs.readFile('/path/to/client.pem'),
    key: await fs.readFile('/path/to/client.key'),
  },
};

// Client (used by code that starts/queries/signals workflows)
const connection = await Connection.connect({ address: 'temporal.internal:7233', tls });
const client = new Client({ connection });

// Worker (long-running process that polls task queues)
const nativeConnection = await NativeConnection.connect({ address: 'temporal.internal:7233', tls });
const worker = await Worker.create({
  connection: nativeConnection,
  namespace: 'default',
  taskQueue: 'my-queue',
  workflowsPath: require.resolve('./workflows'),
});
```

Notes:
- `tls: true` (or simply providing TLS options) enables encryption; `clientCertPair` is what makes it *mutual*.
- `serverNameOverride` is the client-side equivalent of the server's `serverName` concern: it sets the SNI / name checked against the server cert. Use it whenever you connect by IP.
- If you supply an auth token (JWT) for authorization, that is set separately as a gRPC metadata header, not in the TLS block. See `authorization.md`.

## Pre-flight checklist

Before declaring an mTLS config done, confirm:

1. Every untrusted CA is listed in all three required spots (internode server `clientCaFiles`, internode client `rootCaFiles`, frontend server `clientCaFiles`).
2. `serverName` (server config) and `serverNameOverride` (client) match a DNS SAN in the relevant cert, or the cert carries correct IP SANs.
3. Internode server certs have no EKUs or both ServerAuth + ClientAuth.
4. `internode.server` cert/key are present on every role when `requireClientAuth` is true.
5. The client presents a cert chaining to a CA listed in the frontend's `clientCaFiles`.
