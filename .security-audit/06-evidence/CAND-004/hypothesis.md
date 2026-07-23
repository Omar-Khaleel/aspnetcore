# CAND-004 hypothesis

Hypothesis: malformed HTTP/1 requests combining `Transfer-Encoding` and `Content-Length`, or using ambiguous transfer-coding lists, could cause Kestrel and a downstream/proxy layer to disagree on request body framing, enabling request smuggling.

Security invariant: when `Transfer-Encoding` is present for HTTP/1, Kestrel must reject non-final chunked encodings and must not let a conflicting `Content-Length` influence application-visible body framing.

Decisive proof would require a local dynamic parser/proxy differential showing Kestrel accepts a request boundary that another realistic front end parses differently. Decisive disproof for this stage is source and test evidence that Kestrel enforces final chunked coding and suppresses conflicting content length before app body selection.
