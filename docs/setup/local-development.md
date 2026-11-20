# Local development

1. Use Node.js 20+ and pnpm 9+.
2. Install dependencies with `pnpm install`.
3. Run `pnpm test:clinical`.
4. Run `pnpm build`.
5. Use deployment-specific environment files based on `.env.example`; never commit secrets or real patient data.

The Ollama process is not part of clinical scoring and must not be used to calculate scores or risk tiers.