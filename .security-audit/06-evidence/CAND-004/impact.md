# Impact validation

Status: `REJECTED` for this specific hypothesis in the current local audit round.

Observed source evidence shows HTTP/1 request body selection calls `HttpHeaders.GetFinalTransferCoding()` when `Transfer-Encoding` exists, rejects values whose final transfer coding is not `chunked`, and when valid chunked encoding is present it moves any `Content-Length` to `X-Content-Length` and clears the parsed content length before selecting a chunked body. Request header parsing separately rejects multiple `Content-Length` values that differ.

Observed test evidence covers ambiguous transfer-coding lists and verifies the content-length-to-`X-Content-Length` behavior when transfer encoding is chunked.

No request-smuggling impact was demonstrated. Dynamic differential testing remains blocked by unavailable repository-local .NET SDK bootstrap under the current proxy restrictions.
