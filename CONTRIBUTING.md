# Contributing

TherapySculpt is a challenge/demo scaffold. Do not remove, rename, destructively overwrite, or silently replace existing code, docs, configuration, or features. Keep unused work aside. Superseded material may be moved or copied to `docs/archive/` only after explicit approval and with a dated explanatory note.

Each cycle follows **inspect -> plan -> additive change -> test -> docs -> review**.

## Required gates

- Run `pnpm test:clinical`.
- Run `pnpm build`.
- Run diagnostics/type checks where available.
- Preserve user-modified configuration, including web app `tsconfig.json` files.
- Obtain clinical safety review for scoring, crisis, consent, patient messaging, or emergency routing changes.
- Update relevant documentation and `docs/requirements/initial-details-traceability.md` when requirements change.

Never use an LLM to calculate clinical scores or risk tiers, and never add real patient data or unverified emergency contacts.