# VULN-187171 — ASP.NET Core OutputCache authenticated-response replay

## Outcome

**REPORTABLE MATERIAL NEW EVIDENCE — original fix correlation plus a validated incomplete-fix bypass.**

This folder contains fully local, no-cloud evidence for the issue submitted to MSRC as `VULN-187171` on 2026-05-10.

The evidence now establishes two independent facts:

1. Microsoft later changed ASP.NET Core for the exact cross-user replay scenario described in the original report.
2. The shipped fix checks only `ClaimsPrincipal.Identity`, while ASP.NET Core Authorization treats a principal as authenticated when **any** identity in `ClaimsPrincipal.Identities` is authenticated. This mismatch leaves ASP.NET Core 9.0.17 vulnerable even when Authentication and Authorization run before OutputCache.

No Azure resource, Redis service, subscription, tenant, managed identity, paid product, or external account is required.

## Original issue and Microsoft fix correlation

The original proof tested ASP.NET Core 9.0.15 and demonstrated that OutputCache could store an authenticated Alice response and replay it to Bob or an anonymous request when `UseOutputCache()` appeared before Authentication/Authorization.

The vulnerable `DefaultPolicy` implementation remained unchanged in 9.0.16.

On 2026-06-09, after the report was submitted, Microsoft merged:

- Commit: `1a638c9050d54510c9e48fea351636d736956196`
- PR: `#67110`
- Title: `Avoid caching responses for authenticated users`

The upstream description states that when authentication middleware appears after OutputCache and authentication does not use the Authorization header, a page intended for one user can be cached and served to anonymous or other users.

The fix shipped in 9.0.17 and added checks equivalent to:

```csharp
context.HttpContext.User?.Identity?.IsAuthenticated == true
```

before cache lookup and response storage.

## Validated version-differential proof

`LocalVersionProof` runs one identical Cookie Authentication application under official runtime images:

- `mcr.microsoft.com/dotnet/aspnet:9.0.16`
- `mcr.microsoft.com/dotnet/aspnet:9.0.17`

The application uses only:

- standard Cookie Authentication;
- `AddOutputCache()` without a custom policy;
- a protected `.RequireAuthorization().CacheOutput()` endpoint;
- independent Alice and Bob cookie jars;
- a protected non-cached control endpoint.

Validated result:

### 9.0.16

```text
ALICE_RESPONSE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1
BOB_RESPONSE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1
BOB_AGE_HEADER=Age: 0
ANONYMOUS_STATUS=200
ANONYMOUS_RESPONSE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1
NO_CACHE_BOB_RESPONSE=NO_CACHE_USER=bob;ACCOUNT=account-bob
```

### 9.0.17

```text
ALICE_RESPONSE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1
BOB_RESPONSE=PRIVATE_USER=bob;ACCOUNT=account-bob;EXEC_COUNT=2
BOB_AGE_HEADER=
ANONYMOUS_STATUS=401
NO_CACHE_BOB_RESPONSE=NO_CACHE_USER=bob;ACCOUNT=account-bob
```

This proves the exact vulnerable-to-fixed transition without Redis or a distributed environment.

## Incomplete-fix bypass on 9.0.17

### Security invariant mismatch

ASP.NET Core Authorization's `DenyAnonymousAuthorizationRequirement` determines that a user is authenticated when:

```csharp
user.Identities.Any(identity => identity.IsAuthenticated)
```

OutputCache 9.0.17 instead checks only:

```csharp
user.Identity?.IsAuthenticated
```

`ClaimsPrincipal.Identity` returns the first identity. A valid principal can therefore contain:

1. an unauthenticated first identity; and
2. an authenticated second identity.

Authorization accepts that principal because an authenticated identity exists. OutputCache treats the same principal as unauthenticated because the first identity is not authenticated.

### Realistic construction

`IncompleteFixProof` uses standard Cookie Authentication and the documented `IClaimsTransformation` extension point. Authentication creates a normal authenticated Cookie principal. The claims transformation prepends an unauthenticated identity, producing the exact multi-identity principal that the framework supports.

The middleware order is the recommended order:

```csharp
app.UseAuthentication();
app.UseAuthorization();
app.UseOutputCache();
```

The protected endpoint is:

```csharp
.RequireAuthorization()
.CacheOutput();
```

### Validated vulnerable case

Under official ASP.NET Core 9.0.17, with the unauthenticated identity first:

```text
ALICE_PRIVATE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=False;ANY_AUTH=True;AUTH_METADATA=True;ALLOW_ANON=False;IDENTITY_COUNT=2
BOB_PRIVATE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=False;ANY_AUTH=True;AUTH_METADATA=True;ALLOW_ANON=False;IDENTITY_COUNT=2
BOB_AGE_HEADER=Age: 0
BOB_NO_CACHE=NO_CACHE_USER=bob;ACCOUNT=account-bob;PRIMARY_AUTH=False;ANY_AUTH=True
ANONYMOUS_STATUS=401
```

Important controls:

- Authorization succeeded for Alice and Bob because `ANY_AUTH=True`.
- Endpoint metadata shows `AUTH_METADATA=True` and `ALLOW_ANON=False`.
- Bob's non-cached protected endpoint correctly returned Bob.
- Bob's cached protected endpoint returned Alice with `Age: 0` and did not execute again.
- Anonymous access remained 401, proving the bypass is cross-user authenticated disclosure rather than an unprotected endpoint.

### Identity-order control

With the authenticated identity first, under the same runtime and middleware configuration:

```text
ALICE_PRIVATE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=True;ANY_AUTH=True
BOB_PRIVATE=PRIVATE_USER=bob;ACCOUNT=account-bob;EXEC_COUNT=2;PRIMARY_AUTH=True;ANY_AUTH=True
BOB_AGE_HEADER=
```

Only identity order changes the security result. This directly isolates the incomplete `User.Identity` check as the root cause.

## Reference remediation

The research branch changes both OutputCache authentication decisions to:

```csharp
context.HttpContext.User?.Identities.Any(static identity => identity.IsAuthenticated) == true
```

The check is applied before:

- cache lookup; and
- response storage.

A regression test, `AuthenticatedSecondaryIdentityIsNotCached`, creates an unauthenticated primary identity and authenticated secondary identity, sends Alice and Bob requests to the same cache key, and requires two endpoint executions with no `Age` response.

## Reproduction

Version comparison:

```bash
cd eng/security-research/VULN-187171/LocalVersionProof
chmod +x run-version-comparison.sh
./run-version-comparison.sh
```

Incomplete-fix bypass:

```bash
cd eng/security-research/VULN-187171/IncompleteFixProof
chmod +x run-incomplete-fix-proof.sh
./run-incomplete-fix-proof.sh
```

Both scripts generate:

- raw request and response headers;
- response bodies;
- exact runtime listings;
- container logs;
- control results;
- SHA-256 checksums;
- compressed evidence archives.

## Submission strategy

Do not submit the old report unchanged and do not describe this only as middleware misordering.

Reply to the existing `VULN-187171` case with:

1. the post-submission Microsoft fix correlation;
2. the 9.0.16 versus 9.0.17 differential evidence;
3. the 9.0.17 multi-identity bypass using recommended middleware ordering;
4. the Authorization-versus-OutputCache source mismatch;
5. the reference fix and regression test;
6. a request for reassessment, fix correlation, and bounty eligibility.

If MSRC explicitly instructs the researcher to open a separate case for the incomplete fix, use the same evidence but clearly cross-reference `VULN-187171` and PR `#67110`.
