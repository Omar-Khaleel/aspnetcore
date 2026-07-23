# Language and ecosystem playbooks

Use only the sections relevant to the repository.

## C and C++

- Build with warnings and debug symbols.
- Use ASan/UBSan; add MSan/TSan when prerequisites support them.
- Inspect parser lengths, integer conversions, ownership, FFI, callbacks, and error unwinding.
- Prefer coverage-guided fuzz targets at externally reachable parsers and stateful APIs.
- Minimize crashing inputs and confirm supported build configuration.

## Rust

- Separate safe-code logic flaws from `unsafe` memory invariants.
- Inspect FFI, `unsafe` blocks, lifetime assumptions, path handling, serde formats, integer casts, and concurrency.
- Use cargo tests, clippy, fuzzing, and sanitizers/Miri where compatible.

## Go

- Inspect HTTP/RPC middleware ordering, context identity, URL/path normalization, archive handling, command execution, template use, and goroutine races.
- Use `go test ./...`, race detector, fuzz tests, and static analysis.
- Review interface/nil subtleties and error paths that continue with partial authority.

## Java/Kotlin/JVM

- Inspect deserialization, reflection, class loading, expression languages, XML, archive paths, process execution, URL handlers, and authorization annotations/middleware.
- Review framework defaults and filter/interceptor ordering.
- Use unit/integration tests, CodeQL/Semgrep, dependency scans, and JVM fuzzing when suitable.

## C#/.NET

- Inspect ASP.NET middleware/filter order, claims and tenant selection, serializers, reflection, assembly loading, process execution, file providers, archive APIs, and Windows-specific ACL/path semantics.
- Test supported target frameworks and hosting modes.
- Review cancellation, async races, and cache key isolation.

## JavaScript/TypeScript/Node

- Inspect prototype pollution paths, dynamic import/require, child processes, template engines, path normalization, SSRF, redirects, package scripts, and authorization middleware order.
- Trace attacker data through validation schemas and object merges.
- Test both source and built/transpiled output when behavior may differ.

## Python

- Inspect pickle/yaml/eval/exec, subprocess shell use, tar/zip extraction, path joins, template engines, SSRF, import/plugin loading, and authorization decorators.
- Review type/shape assumptions and error fallbacks.
- Use tests, bandit/semgrep as leads, dependency scans, and Python fuzzing when parsers are present.

## PHP/Ruby

- Inspect dynamic dispatch, deserialization, template rendering, file inclusion, command execution, mass assignment, route/middleware authorization, and package hooks.
- Review framework magic and environment-dependent defaults.

## CI actions and build tooling

- Map which event supplies code and which token/secrets execute it.
- Distinguish trusted base branch code from untrusted PR code.
- Inspect artifact names/paths, caches, output files, command construction, checkout refs, reusable workflows, and permission inheritance.
- Demonstrate crossing from untrusted contribution to protected secret, release, environment, or repository authority.

## Cloud/identity tooling

- Record authority source independently for management plane and data plane.
- Prove subscription/project/tenant/resource binding, not merely optional labeling.
- Use multiple controlled principals and tenants/subscriptions where the claim requires separation.
- Verify downstream service authorization and actual resource ownership.
