# CAND-003 hypothesis

## Title
Remote authentication callback state/nonce confusion could allow forged or replayed login callbacks.

## Security invariant
An externally supplied OAuth/OIDC callback must be accepted only when it is bound to a locally initiated authentication challenge for the same scheme/workflow, including protected state, correlation cookie, and OIDC nonce where required.

## Decisive proof target
A reportable issue would require a locally reproducible callback that creates or upgrades an ASP.NET Core principal without a valid protected state/correlation cookie/nonce, or with a callback/token from a different workflow.

## Disproof target
The claim is rejected if source evidence shows callback processing unprotects state before use, validates the correlation cookie, deletes one-time markers, and passes nonce into protocol validation, and no bypassable sibling path is demonstrated.
