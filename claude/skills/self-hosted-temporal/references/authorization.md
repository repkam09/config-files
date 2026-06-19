# Authorization: custom ClaimMapper and Authorizer

This is how you restrict *who can do what* on a self-hosted Temporal Service. It is separate from mTLS (transport encryption/identity). You typically want both.

> Critical default: if you do not configure an `Authorizer`, Temporal uses `noopAuthorizer`, which **allows every API call** with no access control. Anyone who can reach the frontend can invoke anything, including admin operations. A self-hosted production deployment is effectively open until you wire in an Authorizer **and** a ClaimMapper. A ClaimMapper alone does nothing without an Authorizer to act on the claims.

## The two plugins, and where the request flows

On every incoming frontend API call, when these plugins are configured:

1. **`ClaimMapper`** runs first. It takes the caller's auth info (a JWT from the gRPC `authorization` header, and/or the x.509 subject from their mTLS cert) and produces `Claims` about the caller's roles.
2. **`Authorizer`** runs next. It trusts those `Claims` (it assumes authentication already happened) and decides `DecisionAllow` or `DecisionDeny` for the specific call target.

Both are **Go** plugins. They are compiled into a custom Temporal Server binary using the `go.temporal.io/server` module. Even if your workflows/clients are TypeScript, these live in Go. The Node side's only job is to attach the auth token to outgoing calls (see "Supplying tokens from a client" below).

Sample implementation: https://github.com/temporalio/samples-server/blob/main/extensibility/authorizer

## Core types

- **`AuthInfo`** - passed to `GetClaims`. Holds the auth token extracted from the gRPC `authorization` header, plus a pointer to a `pkix.Name` (the x.509 Distinguished Name from the caller's mTLS cert). So claims can derive from the JWT, the cert subject, or both.
- **`Claims`** - permission claims for the caller. A `Role` is a bitmask combining role constants:

  ```go
  role := authorization.RoleReader | authorization.RoleWriter
  ```

  Role constants map to Temporal's four permission levels: `read`, `write`, `worker`, `admin`. `Claims` carries a `System` role plus a per-namespace role map (`Namespaces[namespace]`).
- **`CallTarget`** - what the Authorizer is deciding about: API name, namespace, etc.
- The Authorizer returns `DecisionAllow` or `DecisionDeny`.

## The default JWT ClaimMapper

Temporal ships a JWT ClaimMapper you can use as-is or fork:

- Create with `authorization.NewDefaultJWTClaimMapper`, passing a `TokenKeyProvider`, a `*config.Authorization`, and a logger.
- It validates token signatures using public keys fetched from issuer JWKS endpoints.
- The `TokenKeyProvider` (`authorization.NewDefaultTokenKeyProvider(cfg, logger)`) pulls and refreshes public keys in JWKS format (RSA and ECDSA). Configure issuer key URIs and refresh interval under `config.Config.Global.Authorization.JWTKeyProvider`. Example JWKS endpoint shape: `https://YOUR_DOMAIN/.well-known/jwks.json`.

### Expected JWT format

Token is passed as `Bearer <token>`. The permissions claim is a list of `"<namespace> : <permission>"` strings, where permission is one of `read`, `write`, `worker`, `admin`. Multiple permissions for the same namespace override each other. Example payload:

```json
{
  "permissions": ["temporal-system:read", "namespace1:write"],
  "aud": ["audience"],
  "exp": 1630295722,
  "iss": "Issuer"
}
```

By default the permissions claim is named `permissions`.

## Wiring plugins into a custom server

Configure with the `temporal.WithClaimMapper` and `temporal.WithAuthorizer` server options:

```go
temporalServer, err := temporal.NewServer(
    temporal.WithAuthorizer(newCustomAuthorizer()),
    temporal.WithClaimMapper(func(cfg *config.Config) authorization.ClaimMapper {
        return newCustomClaimMapper(cfg)
    }),
)
```

## Full example: OIDC-backed RBAC

A complete custom server that validates OIDC/JWT tokens and enforces role-based access. This pattern (custom ClaimMapper + Authorizer + custom server `main`, shipped as a Docker image and deployed via Helm) is the standard way to add real auth to self-hosted Temporal.

### Custom ClaimMapper (OIDC)

```go
type OIDCClaimMapper struct {
    issuerURL string
    clientID  string
    jwksURL   string
    keySet    jwk.Set
}

func NewOIDCClaimMapper() *OIDCClaimMapper {
    issuerURL := os.Getenv("TEMPORAL_OIDC_ISSUER_URL")
    clientID := os.Getenv("TEMPORAL_OIDC_CLIENT_ID")
    jwksURL := issuerURL + "/.well-known/jwks.json"

    keySet, err := jwk.Fetch(context.Background(), jwksURL)
    if err != nil {
        return nil
    }
    return &OIDCClaimMapper{issuerURL: issuerURL, clientID: clientID, jwksURL: jwksURL, keySet: keySet}
}

// Implement GetClaims(authInfo *authorization.AuthInfo) (*authorization.Claims, error):
// validate the bearer token against keySet, then map token roles/groups onto
// claims.System and claims.Namespaces[ns] using authorization.Role bit constants.
```

### Custom Authorizer

```go
type OIDCAuthorizer struct{}

func (a *OIDCAuthorizer) Authorize(
    ctx context.Context,
    claims *authorization.Claims,
    target *authorization.CallTarget,
) (authorization.Result, error) {
    // Always let health checks through so the cluster can start and probes pass.
    if authorization.IsHealthCheckAPI(target.APIName) {
        return decisionAllow, nil
    }
    if claims == nil || target.Namespace == "" {
        return decisionAllow, nil
    }

    metadata := api.GetMethodMetadata(target.APIName)
    var userRole authorization.Role
    switch metadata.Scope {
    case api.ScopeCluster:
        userRole = claims.System
    case api.ScopeNamespace:
        userRole = claims.System | claims.Namespaces[target.Namespace]
    default:
        return decisionDeny, nil
    }

    requiredRole := getRequiredRole(metadata.Access)
    if userRole >= requiredRole {
        return decisionAllow, nil
    }
    return decisionDeny, nil
}
```

The Authorizer uses each API's method metadata (cluster- vs namespace-scoped, and required access level) to compare the caller's effective role against what the call requires. Note how it combines `claims.System` with the per-namespace role for namespace-scoped calls.

### Custom server `main`

```go
func main() {
    cfg, err := config.LoadConfig("development", "./config", "")
    if err != nil {
        log.Fatal(err)
    }

    s, err := temporal.NewServer(
        temporal.ForServices(temporal.DefaultServices),
        temporal.WithConfig(cfg),
        temporal.InterruptOn(temporal.InterruptCh()),

        temporal.WithClaimMapper(func(cfg *config.Config) authorization.ClaimMapper {
            return NewOIDCClaimMapper()
        }),
        temporal.WithAuthorizer(&OIDCAuthorizer{}),
    )
    if err != nil {
        log.Fatal(err)
    }
    if err = s.Start(); err != nil {
        log.Fatal(err)
    }
}
```

### Build and deploy the custom image

```bash
docker build -t temporal-auth-server .
docker push temporal-auth-server:latest
```

Point the Helm chart at your image and inject the OIDC settings (use real secrets, not literals):

```yaml
server:
  image:
    repository: temporal-auth-server
    tag: latest
    pullPolicy: Never        # or IfNotPresent once pushed to a real registry
  command: ["/app/temporal-auth-server"]
  additionalEnv:
    - name: TEMPORAL_OIDC_ISSUER_URL
      valueFrom:
        secretKeyRef:
          name: temporal-auth-secrets
          key: issuer_url
    - name: TEMPORAL_OIDC_CLIENT_ID
      valueFrom:
        secretKeyRef:
          name: temporal-auth-secrets
          key: client_id
```

```bash
helm upgrade --install temporal temporal/temporal -f ./k8s/dev/values-dev.yaml -n temporal
```

(Adapted from Bitovi's "Implementing Role-Based Authentication for Self-Hosted Temporal".)

## Supplying tokens from a client

When authorization is enabled, callers must send an `authorization` gRPC header. How you set it depends on SDK.

### TypeScript / Node

Attach the bearer token as gRPC metadata on the connection. Refresh it as needed for short-lived tokens.

```typescript
import { Connection, Client } from '@temporalio/client';

const connection = await Connection.connect({
  address: 'temporal.internal:7233',
  tls: { /* mTLS options if used; see security-mtls.md */ },
  metadata: {
    authorization: `Bearer ${await getAccessToken()}`,
  },
});
const client = new Client({ connection });
```

For workers, set the same `metadata` on `NativeConnection.connect(...)`. If tokens expire, recreate or update the connection metadata before they lapse.

### Java (reference)

Implement `io.temporal.authorization.AuthorizationTokenSupplier`, wrap it in an `AuthorizationGrpcMetadataProvider`, and add it to the service stub's gRPC metadata providers. The supplier is called per request, so it can return rotating tokens:

```java
AuthorizationTokenSupplier tokenSupplier =
    () -> "Bearer <token>";
WorkflowServiceStubsOptions options =
    WorkflowServiceStubsOptions.newBuilder()
        .addGrpcMetadataProvider(new AuthorizationGrpcMetadataProvider(tokenSupplier))
        .build();
```

## Single sign-on

SSO is implemented through the same `ClaimMapper` + `Authorizer` plugins (default JWT ClaimMapper works as a base). Web UI SSO is configured separately via UI env vars (`TEMPORAL_AUTH_*`); see `deployment.md`. UI auth and server API authorization are distinct layers; configure both.

## Verification checklist

1. Both a `ClaimMapper` and an `Authorizer` are wired. A ClaimMapper without an Authorizer leaves you on the noop (open) Authorizer.
2. Health-check APIs are explicitly allowed, or the cluster may fail to start / fail probes.
3. The custom server actually loads the config and starts the default services (`temporal.ForServices(temporal.DefaultServices)`).
4. Clients send `Bearer <token>` in the `authorization` gRPC header, and the token's `permissions` use the `<namespace>:<permission>` format the ClaimMapper expects.
5. JWKS issuer URIs and refresh interval are configured so signature validation keys stay current.
