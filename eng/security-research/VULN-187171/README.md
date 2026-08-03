# VULN-187171 — ASP.NET Core OutputCache authenticated-response replay

## Outcome

This folder contains a no-cloud, no-subscription, version-differential proof for the issue originally submitted to MSRC as `VULN-187171` on 2026-05-10.

The original report demonstrated that ASP.NET Core OutputCache could store a response generated for an authenticated cookie principal when `UseOutputCache()` ran before authentication, and then replay that protected response to another authenticated user or an anonymous request.

Microsoft later merged an upstream change that describes the same scenario and adds the missing post-handler authentication check.

## Timeline and exact source delta

### Reported affected version

The submitted proof tested ASP.NET Core `9.0.15`.

In tag `v9.0.15`, `DefaultPolicy.ServeResponseAsync` rejects storage for:

- responses that emit `Set-Cookie`;
- responses whose status is not 200.

It does **not** reject storage when downstream authentication has populated `HttpContext.User`.

The same vulnerable implementation remains in tag `v9.0.16`.

### Microsoft fix

Upstream commit:

`1a638c9050d54510c9e48fea351636d736956196`

Commit title:

`Merged PR 60873: Avoid caching responses for authenticated users (#67110)`

Commit date:

`2026-06-09`

The commit message states that when authentication middleware appears after OutputCache and authentication is not represented by the Authorization header, an application can cache a page intended for one user and serve it to anonymous or other users.

The source fix adds this check to `DefaultPolicy.ServeResponseAsync`:

```csharp
if (context.HttpContext.User?.Identity?.IsAuthenticated == true)
{
    context.AllowCacheStorage = false;
    return ValueTask.CompletedTask;
}
```

The change is present in tag `v9.0.17` and in the current main branch.

## Why this closes the primary triage objection

The expected objection to the original report was that the vulnerable middleware ordering was merely application misconfiguration.

The later Microsoft change materially weakens that objection:

1. Microsoft changed framework behavior rather than relying only on documentation.
2. The commit description identifies the same order-dependent cross-user/anonymous disclosure scenario.
3. The regression test explicitly exercises authentication both before and after OutputCache.
4. The framework now checks authentication again after downstream middleware executes, proving that the prior request-time check was insufficient.
5. The fix shipped between `9.0.16` and `9.0.17` after the original submission date.

The report should therefore be updated as a fix-correlation submission, not resubmitted as a duplicate.

## Local version-differential proof

`LocalVersionProof` contains one identical application executed under two official ASP.NET Core runtime images:

- `mcr.microsoft.com/dotnet/aspnet:9.0.16`
- `mcr.microsoft.com/dotnet/aspnet:9.0.17`

The application uses:

- standard Cookie Authentication;
- `builder.Services.AddOutputCache()` with no custom policy;
- `UseOutputCache()` before Authentication/Authorization;
- a protected `.RequireAuthorization().CacheOutput()` endpoint;
- separate Alice and Bob cookies;
- no public cache headers;
- no Azure, Redis service, subscription, tenant, or paid product.

Expected result:

### 9.0.16

- Alice requests `/private` and generates a private response.
- Bob requests the same endpoint using Bob's independent cookie.
- Bob receives Alice's cached body and the response includes `Age`.
- An anonymous request also receives Alice's cached body.
- `/private-nocache` still resolves Bob correctly, proving the identities and authorization system are functioning.

### 9.0.17

- Alice's authenticated response is not stored.
- Bob executes the handler as Bob and receives Bob's account data.
- The anonymous request receives 401.

Run:

```bash
cd eng/security-research/VULN-187171/LocalVersionProof
chmod +x run-version-comparison.sh
./run-version-comparison.sh
```

Requirements:

- Docker
- curl
- Bash

The script records exact installed runtime versions, raw headers and bodies, container logs, assertions, SHA-256 checksums, and a compressed evidence archive.

## Remaining limitation

The `9.0.17` fix prevents storage of newly generated authenticated responses. It does not make arbitrary middleware ordering universally safe: a cache entry created for an anonymous endpoint can still be served before later authentication middleware executes. Microsoft's added negative test documents this remaining ordering rule.

That limitation does not negate the reported issue. The original claim is narrower: authenticated private output could be stored and replayed cross-user. The upstream change directly fixes that claim.

## Submission strategy

Do not create a new duplicate report. Add the following to the existing `VULN-187171` submission:

- original submission timestamp;
- upstream commit and PR identifiers;
- vulnerable/fixed source comparison;
- completed local version-differential evidence archive;
- request that MSRC correlate the fix with the report and reassess eligibility.
