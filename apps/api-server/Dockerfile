# ==============================================================================
# TherapySculpt - Production API Server Dockerfile
# Stack: Node.js 20 Alpine | Turborepo | pnpm | Prisma | Fastify
# Regulatory Compliance: UAE Federal Law No. 2 of 2019 / DoH ADHICS v2
# Region: UAE North (uaenorth)
# ==============================================================================

# 1. Base Image
FROM node:20-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV TURBO_TELEMETRY_DISABLED=1
ENV DO_NOT_TRACK=1
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

# 2. Prune Workspace
FROM base AS pruner
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN npm install -g turbo@^2
COPY . .
RUN turbo prune @therapy-sculpt/api-server --docker

# 3. Builder
FROM base AS builder
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app

# Install dependencies from pruned lockfile and preserve npmrc
COPY --from=pruner /app/.npmrc* ./
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
RUN pnpm install --frozen-lockfile=false

# Copy pruned source files & shared config packages
COPY --from=pruner /app/out/full/ .
COPY --from=pruner /app/packages/config ./packages/config

# Generate Prisma Client if database package is present
RUN if [ -f "packages/database/prisma/schema.prisma" ]; then \
      pnpm --filter @therapy-sculpt/database db:generate; \
    fi

# Build api-server and all internal dependencies
RUN npx turbo run build --filter=@therapy-sculpt/api-server...

# Remove development dependencies for a lean production layer
RUN pnpm prune --prod --no-optional

# 4. Production Runner
FROM node:20-alpine AS runner
RUN apk add --no-cache libc6-compat openssl dumb-init
WORKDIR /app

# Enforce least privilege with non-root system user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

COPY --from=builder --chown=nodejs:nodejs /app .

USER nodejs

ENV NODE_ENV=production
ENV PORT=4000
ENV HOST=0.0.0.0
ENV UAE_REGION=uaenorth

EXPOSE 4000

# Dumb-init handles PID 1 and forward process termination signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "apps/api-server/dist/main.js"]
