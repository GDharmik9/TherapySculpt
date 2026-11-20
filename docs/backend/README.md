# Backend

`apps/api-server` is a minimal Fastify entry point. Workers separate scoring, crisis dispatch, and Malaffi-sync responsibilities. Shared contracts and clinical-core keep behavior consistent across clients.

Before production, add reviewed authentication, authorization, idempotency, queue durability, rate limits, and clinical audit integration. Do not add LLM calls to scoring or tier selection.