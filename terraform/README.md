## NOTES
- AuthMat owns, and serves the key. Single source of truth
- Kong fetches the JWKS from AuthMat and caches it
- Avoids AWS costs and network hops

### FLOW

```text
AuthMat  → exposes GET /.well-known/jwks.json
Kong     → fetches JWKS on startup + caches with TTL
Kong     → verifies every inbound JWT locally against cached public key
DocKeep  → receives request, trusts Kong already verified it
```