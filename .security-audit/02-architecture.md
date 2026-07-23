# Security-oriented architecture map

## Repository shape

ASP.NET Core is a large multi-component .NET repository containing server stacks, middleware, security/authentication packages, Blazor components, SignalR, MVC/Razor, gRPC integration, tooling, installers, analyzers, shared libraries, fuzzing targets, tests, samples, and engineering automation. The generated inventory counted 16,606 files and approximately 101 MB of content. Dominant languages are C#, JSON, TypeScript, JavaScript, C/C++ headers, YAML, C++, PowerShell, Shell, and Java.

## Shipped or security-relevant component families

| Component family | Representative paths | Authority / protected assets | Major entry points |
| --- | --- | --- | --- |
| HTTP abstractions, routing, static assets | `src/Http`, `src/StaticAssets`, `src/Shared/StaticWebAssets` | request routing, file serving boundaries, response metadata | HTTP requests, route patterns, static asset manifests, file providers |
| Servers | `src/Servers/Kestrel`, `src/Servers/HttpSys`, `src/Servers/IIS` | network parsing, TLS/client certs, native host integration, process boundary | sockets, HTTP/1/2/3 frames, IIS/ANCM integration, Windows HTTP.sys |
| Security packages | `src/Security` | authentication, authorization, token/cookie handling, remote auth state | cookies, bearer/JWT/OIDC/OAuth/WsFed/Negotiate/certificate inputs |
| MVC/Razor/Components | `src/Mvc`, `src/Razor`, `src/Components` | model binding, rendering, antiforgery, browser/server boundary, SignalR circuits | HTTP forms/JSON, Razor compilation, component parameters, browser events |
| SignalR | `src/SignalR` | hub method authorization, connection identity, protocol parsing | WebSockets/SSE/LongPolling, JSON/MessagePack protocols, Redis backplane |
| Data protection and caching | `src/DataProtection`, `src/Caching` | cryptographic keys, protected payloads, cache isolation and expiration | key rings, stores, Redis/SQL/distributed cache operations |
| Tools and build/release | `src/Tools`, `eng`, `.github` | developer machine, CI tokens, package/release authority | CLI args, project files, generated code, CI workflow events, archives |
| Native/installers | `src/Installers`, server native integration | Windows installation state, IIS module configuration | MSI/Wix/custom actions, native server shims |

## Data-flow and authority observations

- Lower-trust HTTP input reaches routing, middleware, model binding, parsers, auth handlers, static file/file-provider abstractions, and SignalR protocols before application code decides final authorization.
- Static asset serving relies on build-produced manifests and file providers; manifest path selection is application/developer controlled and resolved relative to `AppContext.BaseDirectory` for relative paths.
- Authentication handlers in `src/Security/Authentication` are authority translators: external tokens/cookies/remote-provider responses become ASP.NET Core identities and claims.
- Server components translate network frames and native server state into managed `HttpContext` features; parser and state-machine correctness is security critical.
- Engineering scripts and CI workflows have supply-chain relevance, but executing untrusted product build scripts was avoided during this audit.

## Lifecycle map

- Build/restore: `eng/build.sh`, `eng/build.ps1`, MSBuild props/targets, NuGet configuration, generated sources, TypeScript clients.
- Startup: app host configures server, middleware, endpoint routing, auth, static assets, SignalR hubs, and component endpoints.
- Runtime: HTTP/network parsers, middleware ordering, endpoint metadata, auth decisions, cache/key stores, file providers, backplanes.
- Update/release: Arcade/eng automation, package generation, installers, signing/release workflows.
- Tests/fuzzing: extensive unit/functional tests and `src/Fuzzing`, useful for future deeper dynamic validation.

## High-centrality enforcement points

- Endpoint metadata and authorization helpers in routing/security packages.
- Authentication handlers that validate issuer/audience/state/correlation/nonce and convert tokens to claims.
- File providers and static asset manifest resolution serving paths from content roots.
- Kestrel/HttpSys/IIS request parsing and feature population.
- Build and release scripts that fetch/extract tools or run generated code.
