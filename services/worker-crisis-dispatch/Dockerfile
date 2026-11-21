# ==============================================================================
# TherapySculpt - Production Worker Crisis Dispatch Dockerfile
# Stack: Node.js 20 Alpine | Turborepo | pnpm | Crisis Dispatch Service
# ==============================================================================

FROM node:20-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV TURBO_TELEMETRY_DISABLED=1
ENV DO_NOT_TRACK=1
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

FROM base AS pruner
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN npm install -g turbo@^2
COPY . .
RUN turbo prune @therapy-sculpt/worker-crisis-dispatch --docker

FROM base AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy root configs & pruned lockfile
COPY --from=pruner /app/.npmrc* ./
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
RUN pnpm install --frozen-lockfile=false

# Copy pruned source files & shared config packages
COPY --from=pruner /app/out/full/ .
COPY --from=pruner /app/packages/config ./packages/config

RUN npx turbo run build --filter=@therapy-sculpt/worker-crisis-dispatch...
RUN pnpm prune --prod --no-optional

FROM node:20-alpine AS runner
RUN apk add --no-cache libc6-compat dumb-init
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

COPY --from=builder --chown=nodejs:nodejs /app .

USER nodejs

ENV NODE_ENV=production
ENV UAE_REGION=uaenorth

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "services/worker-crisis-dispatch/dist/index.js"]
