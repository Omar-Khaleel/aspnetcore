# CAND-003 limitations

- `dotnet` was unavailable, so the existing authentication tests could not be executed in this container.
- No controlled IdP/callback lab with real tokens was available.
- The finding is based on source tracing and existing test/source structure, not dynamic callback execution.
- Custom application event handlers can intentionally override parts of the workflow; this audit did not treat trusted application customization as a framework vulnerability.
