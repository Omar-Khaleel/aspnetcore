# MSRC follow-up draft — VULN-187171

Hello,

I am providing material new evidence for `VULN-187171`, originally submitted on May 10, 2026.

This update contains:

1. source and runtime evidence that Microsoft later fixed the exact scenario described in my original report; and
2. a validated bypass of that fix in ASP.NET Core 9.0.17 and current source, using the recommended middleware ordering and the standard `IClaimsTransformation` extension point.

## 1. Correlation with Microsoft's post-submission fix

The original report demonstrated cross-user replay of protected Cookie Authentication responses when OutputCache stored Alice's private response and returned it to Bob or an anonymous request.

After my submission, Microsoft merged:

- Commit: `1a638c9050d54510c9e48fea351636d736956196`
- PR: `#67110`
- Date: June 9, 2026
- Title: `Avoid caching responses for authenticated users`

The upstream description states that if authentication middleware appears after OutputCache and non-Authorization-header authentication is used, an application can cache a page intended for a specific user and serve it to anonymous or other users.

This is the same root cause and cross-user impact reported in `VULN-187171` on May 10.

### Version-level confirmation

The affected `DefaultPolicy.cs` source is identical in ASP.NET Core 9.0.15 and 9.0.16:

- `v9.0.15`: `cc9ea67ec2ddb815724ae5127cc97c6d1e0b8a50`
- `v9.0.16`: `cc9ea67ec2ddb815724ae5127cc97c6d1e0b8a50`

The fix appears in 9.0.17:

- `v9.0.17`: `1f633dbaff83d076f45dab99d6bc685037aec11a`

The fix adds authentication checks before cache lookup and response storage using:

```csharp
context.HttpContext.User?.Identity?.IsAuthenticated == true
```

### Local version-differential result

I executed one identical application under the official ASP.NET Core 9.0.16 and 9.0.17 runtime images. The application uses standard Cookie Authentication, no custom OutputCache policy, independent Alice and Bob sessions, and a protected `.RequireAuthorization().CacheOutput()` endpoint.

ASP.NET Core 9.0.16:

```text
ALICE_RESPONSE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1
BOB_RESPONSE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1
BOB_AGE_HEADER=Age: 0
ANONYMOUS_STATUS=200
ANONYMOUS_RESPONSE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1
NO_CACHE_BOB_RESPONSE=NO_CACHE_USER=bob;ACCOUNT=account-bob
```

ASP.NET Core 9.0.17:

```text
ALICE_RESPONSE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1
BOB_RESPONSE=PRIVATE_USER=bob;ACCOUNT=account-bob;EXEC_COUNT=2
BOB_AGE_HEADER=
ANONYMOUS_STATUS=401
NO_CACHE_BOB_RESPONSE=NO_CACHE_USER=bob;ACCOUNT=account-bob
```

This independently confirms the vulnerable-to-fixed transition without Azure, Redis, a subscription, or an external tenant.

## 2. The 9.0.17 fix is incomplete for multi-identity principals

ASP.NET Core uses two different definitions of an authenticated principal.

Authorization's `DenyAnonymousAuthorizationRequirement` accepts the user when:

```csharp
user.Identities.Any(identity => identity.IsAuthenticated)
```

OutputCache 9.0.17 and current source reject caching only when:

```csharp
user.Identity?.IsAuthenticated == true
```

`ClaimsPrincipal.Identity` is the first identity. A supported principal can contain an unauthenticated first identity and an authenticated second identity. Authorization accepts it, but OutputCache treats it as unauthenticated and allows both cache lookup and storage.

A review comment on PR `#67110` also identified this exact concern and recommended checking all identities, but the merged implementation still checks only `User.Identity`.

### Reproduction uses recommended middleware ordering

The new proof uses:

```csharp
app.UseAuthentication();
app.UseAuthorization();
app.UseOutputCache();
```

It does not depend on placing OutputCache before authentication.

The application uses standard Cookie Authentication. A normal authenticated Cookie principal is created first. The documented `IClaimsTransformation` extension point then prepends one unauthenticated identity. The protected endpoint remains:

```csharp
.RequireAuthorization()
.CacheOutput();
```

### Validated 9.0.17 result

With the unauthenticated identity first and authenticated identity second:

```text
ALICE_PRIVATE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=False;ANY_AUTH=True;AUTH_METADATA=True;ALLOW_ANON=False;IDENTITY_COUNT=2
BOB_PRIVATE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=False;ANY_AUTH=True;AUTH_METADATA=True;ALLOW_ANON=False;IDENTITY_COUNT=2
BOB_AGE_HEADER=Age: 0
BOB_NO_CACHE=NO_CACHE_USER=bob;ACCOUNT=account-bob;PRIMARY_AUTH=False;ANY_AUTH=True
ANONYMOUS_STATUS=401
```

Security interpretation:

- Both Alice and Bob pass Authorization because `ANY_AUTH=True`.
- The endpoint is protected: `AUTH_METADATA=True` and `ALLOW_ANON=False`.
- Bob's non-cached control endpoint returns Bob correctly.
- Bob's cached protected request returns Alice with `Age: 0` and `EXEC_COUNT=1`, proving the handler did not execute for Bob.
- Anonymous access remains 401, isolating the impact to cross-user disclosure among authenticated sessions.

### Identity-order control

With the authenticated identity first, while all other configuration remains identical:

```text
ALICE_PRIVATE=PRIVATE_USER=alice;ACCOUNT=account-alice;EXEC_COUNT=1;PRIMARY_AUTH=True;ANY_AUTH=True
BOB_PRIVATE=PRIVATE_USER=bob;ACCOUNT=account-bob;EXEC_COUNT=2;PRIMARY_AUTH=True;ANY_AUTH=True
BOB_AGE_HEADER=
```

Only identity order changes the security result, directly isolating the `User.Identity` check as the root cause.

## Reference remediation

Both authentication decisions in `DefaultPolicy` should use the same invariant as Authorization:

```csharp
context.HttpContext.User?.Identities.Any(static identity => identity.IsAuthenticated) == true
```

This check must apply before:

- cache lookup; and
- response storage.

I included a regression test named `AuthenticatedSecondaryIdentityIsNotCached`, which constructs an unauthenticated primary identity and authenticated secondary identity, sends Alice and Bob requests to the same cache key, and requires two endpoint executions with no `Age` response.

## Evidence and validation

The final controlled GitHub Actions validation completed successfully:

- Run ID: `30861448104`
- Runtime proof job: `compare-runtime-patches` — succeeded
- Source regression job: `source-regression-test` — succeeded
- Artifact: `vuln-187171-complete-local-evidence`
- Artifact ID: `8874488862`
- Artifact size: `116739` bytes
- Artifact SHA-256: `0f51c262f5e8aecd8497b122fca4db4911715e257a8ea73f577fb90fbc66298a`

Runtime validation confirmed both the 9.0.16/9.0.17 differential and the 9.0.17 multi-identity bypass.

The source validation used the ASP.NET Core repository build system, restored and compiled the affected OutputCaching source and test projects, and executed the focused regression test. Final result:

```text
Tests succeeded: Microsoft.AspNetCore.OutputCaching.Tests.dll
Build succeeded.
0 Warning(s)
0 Error(s)
```

The artifact contains both evidence archives, raw headers and bodies, exact runtime listings, logs, control results, and SHA-256 manifests.

## Request

Could MSRC please:

1. correlate commit `1a638c9050d54510c9e48fea351636d736956196` / PR `#67110` with the May 10 submission `VULN-187171`;
2. reassess the original report now that Microsoft shipped a fix describing the same root cause and impact;
3. evaluate the validated 9.0.17 multi-identity bypass as material new evidence or an incomplete fix;
4. confirm whether the incomplete-fix variant should remain attached to `VULN-187171` or receive a separate case;
5. review bounty eligibility under the applicable .NET bounty criteria.

The proof uses only researcher-controlled local containers and GitHub-hosted CI. It requires no cloud subscription, tenant resource, external target, or third-party data.

Thank you.
