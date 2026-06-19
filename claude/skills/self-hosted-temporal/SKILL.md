---
name: self-hosted-temporal
description: This skill should be used for self-hosted (open-source) Temporal Service operations, NOT Temporal Cloud. Use it when the user mentions "self-hosted Temporal", "self-hosting Temporal", "Temporal server config", "development.yaml", "temporal server start-dev", "docker-compose Temporal", "Temporal docker compose", "run Temporal locally", "Temporal mTLS", "Temporal TLS config", "internode/frontend TLS", "requireClientAuth", "custom ClaimMapper", "custom Authorizer", "WithClaimMapper", "WithAuthorizer", "default JWT ClaimMapper", "Temporal RBAC", "Temporal OIDC auth", "secure my Temporal cluster", "Temporal namespaces self-hosted", "Temporal dynamic config", "Temporal persistence/datastore config", or builds/deploys their own Temporal Server binary or image. Prefer this skill over general Temporal SDK guidance whenever the question is about hosting, deploying, securing, or authenticating a self-managed Temporal Service.
metadata:
  version: 0.1.0
---

# Skill: self-hosted-temporal

## Overview

This skill covers running and securing the open-source Temporal Service yourself, on your own infrastructure. It deliberately excludes Temporal Cloud: anything that says "Cloud handles this for you" is out of scope here. The whole point of self-hosting is that you own the deployment, the persistence store, the network encryption, and the authorization layer, so this skill focuses on exactly those concerns.

Use it alongside `temporal-developer` (which covers SDK/workflow/activity code). When the question is "how do I write a workflow", that's the other skill. When the question is "how do I deploy, configure, secure, or lock down access to the server", it's this one.

## The mental model that prevents most mistakes

A self-hosted Temporal Service is a control-and-persistence component. Treat it like a database, not like a web app:

- It should never be exposed to the open internet. Run it on a private network and restrict access to trusted internal callers.
- Out of the box it is wide open. If you do not configure an `Authorizer`, Temporal uses `noopAuthorizer`, which allows every API call from anyone who can reach the frontend, including administrative operations. There is no implicit authentication. Security is opt-in.
- Encryption (mTLS) and authorization (ClaimMapper + Authorizer) are two separate, independent layers. mTLS proves who is connecting at the transport level; the Authorizer decides what an authenticated caller is allowed to do. You usually want both in production.

Internalize those three points before touching config, because they explain why almost every production setup looks the way it does.

## Choosing the right path

Pick based on what the user is actually doing. Do not reach for a production deployment when they just want to iterate locally.

**Local development / testing** -> use the Temporal CLI dev server: `temporal server start-dev`. A single binary, no external dependencies, includes the Web UI. This is recommended for local work regardless of where you deploy later. See `references/deployment.md` (Local development section).

**Self-hosting a real service** -> Docker Compose for small/internal setups, server binaries + systemd, or Kubernetes/Helm for scale. A datastore (PostgreSQL, MySQL, or Cassandra) is required, plus optionally Elasticsearch for advanced Visibility. See `references/deployment.md`.

**Configuring the server** -> the `development.yaml` (a.k.a. cluster config) file controls persistence, services, TLS, dynamic config, archival, and more. See `references/configuration.md`.

**Encrypting traffic** -> mTLS for `internode` and/or `frontend`. See `references/security-mtls.md`.

**Restricting who can do what** -> custom `ClaimMapper` + `Authorizer` plugins, typically backed by OIDC/JWT. See `references/authorization.md`.

## How to use the references

Read only what the task needs; each file is self-contained.

- **`references/deployment.md`** - Local dev server, Docker Compose, binaries/systemd, the official repos, and where config lives. Start here for any "how do I run / stand up / spin up Temporal" question.
- **`references/configuration.md`** - The `development.yaml` cluster config reference: `global`, `persistence`/`datastores`, `services`, `publicClient`, `dynamicConfigClient`, archival, namespaces. Read this when editing server config.
- **`references/security-mtls.md`** - TLS/mTLS config structure (`internode` vs `frontend`, `server` vs `client`), certificate requirements and EKU gotchas, `requireClientAuth`, `serverName`, and connecting a TypeScript/Node client/worker over mTLS.
- **`references/authorization.md`** - The `ClaimMapper` and `Authorizer` interfaces, the default JWT ClaimMapper and token key provider, JWT permission format, wiring plugins via `WithClaimMapper`/`WithAuthorizer` into a custom server, a full OIDC RBAC example, supplying tokens from a TypeScript/Node client, and deploying the custom image with Docker/Helm.

## A few things that trip people up

These come up constantly, so flag them proactively when relevant rather than waiting for the user to hit them:

- **ClaimMapper and Authorizer are Go, even if your app is Node.** They are server-side plugins compiled into a custom Temporal Server binary/image via the `go.temporal.io/server` module and `temporal.NewServer(...)` options. Your workflows and clients can be TypeScript, but the auth plugins themselves are Go. The Node side's job is only to *supply* the auth token on outgoing gRPC calls.
- **`numHistoryShards` is immutable.** It is set on first cluster init and ignored forever after. Choose it high enough for peak load up front; changing it later means a new cluster + migration.
- **mTLS `serverName` matters because Temporal talks IP-to-IP.** Without a matching `serverName` (or correct IP SANs in the cert), client-side verification fails. This is the single most common mTLS setup failure.
- **The dev server skips security checks on purpose.** `start-dev` is not for production; it prints a warning saying so. Don't carry its settings into a real deployment.
- **Changing `development.yaml` requires a process restart.** Static config is not hot-reloaded. Use the dynamic config file for values you want to tune at runtime.

## Verify before declaring done

Self-hosted Temporal config is easy to get subtly wrong. Before telling the user a config is good:

- For TLS/mTLS changes, sanity-check that every place a CA is required is actually listed (internode server `clientCaFiles`, internode client `rootCaFiles`, frontend server `clientCaFiles`) and that `serverName`/IP SANs line up. See the checklist in `references/security-mtls.md`.
- For authorization changes, confirm both a `ClaimMapper` and an `Authorizer` are wired (a ClaimMapper alone with the noop Authorizer is still open), and that health-check APIs are allowed so the cluster can start.
- For Docker Compose / binary configs, confirm the datastore is reachable and `numHistoryShards`, `defaultStore`, and `visibilityStore` are all set.

## Source documentation

This skill summarizes the official Temporal self-hosting docs (current as of mid-2026):

- Self-hosted guide: https://docs.temporal.io/self-hosted-guide
- Deployment: https://docs.temporal.io/self-hosted-guide/deployment
- Security: https://docs.temporal.io/self-hosted-guide/security
- Cluster configuration reference: https://docs.temporal.io/references/configuration
- CLI server reference: https://docs.temporal.io/cli/command-reference/server
- Server samples (TLS + Authorizer): https://github.com/temporalio/samples-server
