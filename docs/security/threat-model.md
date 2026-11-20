# Threat model

Primary threats include employer inference, unauthorized clinician access, crisis signal suppression, tampered audit records, data export outside UAE boundaries, prompt/LLM misuse, and unverified emergency information.

Controls include role separation, PostgreSQL policy review, deterministic clinical-core tests, Gate 2 lockout, append-only audit metadata, no LLM scoring, data localization, and explicit resource verification status. Residual risk remains until deployment controls and clinical review are complete.