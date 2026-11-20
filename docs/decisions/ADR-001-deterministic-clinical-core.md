# ADR-001: deterministic clinical core

**Status:** accepted for challenge/demo.

Clinical scores and risk tiers use pure deterministic functions. LLMs may not calculate scores, infer missing answers, or choose escalation. This makes behavior testable and keeps Gate 2 safety decisions explicit.