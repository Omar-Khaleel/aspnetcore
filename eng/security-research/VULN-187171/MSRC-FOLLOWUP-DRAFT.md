# MSRC follow-up draft — VULN-187171

Hello,

I am providing material new evidence for `VULN-187171`, originally submitted on May 10, 2026.

The original report demonstrated cross-user replay of protected cookie-authenticated ASP.NET Core OutputCache responses when `UseOutputCache()` runs before Authentication/Authorization. The proof showed that a response generated for Alice could be stored and later served to Bob or an anonymous request.

After my submission, Microsoft merged the following upstream fix on June 9, 2026:

- Commit: `1a638c9050d54510c9e48fea351636d736956196`
- PR: `#67110`
- Commit title: `Avoid caching responses for authenticated users`

The upstream commit description states:

> If auth middleware was after the output caching middleware and some other auth was used besides the authorization header, then apps could end up caching a page meant for a specific user and then serve the cached page for anonymous or other users.

This is the same root cause and impact described in my May 10 report.

## Version-level source confirmation

The reported ASP.NET Core 9.0.15 implementation of `DefaultPolicy.ServeResponseAsync` did not check whether downstream authentication populated `HttpContext.User`. The identical code remained in 9.0.16.

The Microsoft change adds this post-handler guard:

```csharp
if (context.HttpContext.User?.Identity?.IsAuthenticated == true)
{
    context.AllowCacheStorage = false;
    return ValueTask.CompletedTask;
}
```

The check is present in ASP.NET Core 9.0.17 and current main.

Source blob comparison:

- `v9.0.15 DefaultPolicy.cs`: `cc9ea67ec2ddb815724ae5127cc97c6d1e0b8a50`
- `v9.0.16 DefaultPolicy.cs`: `cc9ea67ec2ddb815724ae5127cc97c6d1e0b8a50`
- `v9.0.17 DefaultPolicy.cs`: `1f633dbaff83d076f45dab99d6bc685037aec11a`

## New no-cloud reproduction

I prepared a self-contained version-differential Docker proof that runs one identical application under the official ASP.NET Core 9.0.16 and 9.0.17 runtime images.

The application uses:

- standard Cookie Authentication;
- `AddOutputCache()` with no custom policy;
- `UseOutputCache()` before Authentication/Authorization;
- `.RequireAuthorization().CacheOutput()` on the protected endpoint;
- separate Alice and Bob cookies;
- no public cache headers;
- no Azure resources, subscription, Redis service, or external tenant.

The expected and asserted result is:

### ASP.NET Core 9.0.16

- Alice's private response is cached.
- Bob, authenticated independently, receives Alice's body with an `Age` header.
- An anonymous request also receives Alice's cached body.
- A protected non-cached control endpoint resolves Bob correctly.

### ASP.NET Core 9.0.17

- Alice's authenticated response is not stored.
- Bob receives a freshly executed Bob response without `Age`.
- An anonymous request receives 401.

The evidence archive contains runtime listings, raw request/response headers and bodies, container logs, assertion results, and SHA-256 checksums.

## Request

Could MSRC please:

1. correlate upstream commit `1a638c9050d54510c9e48fea351636d736956196` / PR `#67110` with `VULN-187171`;
2. confirm whether the report was independently duplicated or whether this change was associated with the submitted issue;
3. reassess the report now that Microsoft shipped a source fix describing the same root cause and cross-user impact;
4. review bounty eligibility under the applicable .NET bounty criteria.

I am not claiming that every middleware ordering is safe after this patch. The narrower reported vulnerability is that the previous DefaultPolicy could store authenticated private output and replay it to another user. Microsoft's post-handler authentication check directly addresses that behavior.

Thank you.
