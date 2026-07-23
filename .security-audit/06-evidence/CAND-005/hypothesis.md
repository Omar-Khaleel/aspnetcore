# CAND-005 hypothesis

SignalR MessagePack protocol parsing might allow attacker-supplied malformed hub messages to bypass binder argument-type checks, deserialize with unsafe MessagePack settings, or consume partial/oversized nested input in a way that crosses from an unauthenticated/low-trust client message into hub invocation authority.

Security invariant: a client-controlled MessagePack hub frame must be parsed with untrusted-data limits and must not create a successful invocation unless the target and argument count/types match the hub binder's authoritative method metadata.
