# ==============================================================================
# TherapySculpt - Production Web Clinician Dockerfile
# Stack: Next.js 15 App Router | Node.js 20 Alpine | Turborepo | pnpm
# Standalone Output Build with Public Environment Args
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
RUN turbo prune @therapy-sculpt/web-clinician --docker

# 3. Builder
FROM base AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies from pruned lockfile and preserve npmrc
COPY --from=pruner /app/.npmrc* ./
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
RUN pnpm install --frozen-lockfile=false

# Copy pruned source files & shared config packages
COPY --from=pruner /app/out/full/ .
COPY --from=pruner /app/packages/config ./packages/config

# Public build-time arguments (inlined by Next.js compiler)
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_UAE_REGION=uaenorth
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_UAE_REGION=$NEXT_PUBLIC_UAE_REGION
ENV NEXT_TELEMETRY_DISABLED=1

# Build web-clinician standalone bundle
RUN npx turbo run build --filter=@therapy-sculpt/web-clinician...

# 4. Production Runner
FROM node:20-alpine AS runner
RUN apk add --no-cache libc6-compat dumb-init
WORKDIR /app

# Non-root user for container security hardening
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy static assets and standalone build output
COPY --from=builder /app/apps/web-clinician/public ./apps/web-clinician/public
COPY --from=builder --chown=nextjs:nodejs /app/apps/web-clinician/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/web-clinician/.next/static ./apps/web-clinician/.next/static

USER nextjs

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"
ENV NEXT_TELEMETRY_DISABLED=1
ENV UAE_REGION=uaenorth

EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "apps/web-clinician/server.js"]
